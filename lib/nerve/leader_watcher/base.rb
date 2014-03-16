require 'zk'
require_relative 'common'
require_relative '../email'

module Nerve
  module LeaderWatcher
    class BaseWatcher
      include Logging

      def initialize(opts={})
        %w{hosts path host failover_path}.each do |required|
          raise ArgumentError, "you need to specify required argument #{required}" unless opts[required]
        end
        @email = Email::new
        @hosts = opts['hosts']
        @path = opts['path']
        @host = opts['host']
        @port = opts['port']
        @failover_path = opts['failover_path']
        @SLAVE_STATE = 'slave'
        @MASTER_STATE = 'master'
        @FAILOVER_INTERVAL = opts['failover_interval']
        @service_home = opts['service_home']
        @previous_leader = ''
        @previous_state = ''
      end

      def start(key)
        @key = key
        @zk = ZK.new(@hosts.shuffle.join(','))
        watcher_callback.call
      end

      def master_node
        return @master_node
      end

      def master?
        if @key == "/#{@leader}"
          return true
        else
          return false
        end
      end

      def terminate_failover(state)
        should_failover = state == @SLAVE_STATE && master? ? true : false
        log.info "[#{@port}] Last State: #{state} Failover: #{should_failover}"

        if should_failover
          failover_time = last_failover
          log.info "----------------> #{failover_time}"
          if failover_time > 0 and failover_time < @FAILOVER_INTERVAL
            log.info("[#{@port}] Should not failover and terminate")
            return true
          else
            log.info("[#{@port}] Should failover and not terminate")
            @zk.set("#{@failover_path}", '')
            return false
          end
        end
        return false
      end

      private

      def action
        log.debug("Am I master? #{master?}")
      end

      def previous_state
        begin
          file = File.open("/tmp/pg.state")
          state = file.gets
        rescue Exception => e
          log.info("Failed to open state file assuming new node #{e}")
          state = ''
        end
        return state.strip
      end

      def node_state_update(state)
        case state
        when ''
          if master?
            state_update = StatusChange::STARTUP
            log.info("[#{@port}] New Node. Setting as  #{@MASTER_STATE}")
          else
            state_update = StatusChange::DEMOTED
            log.info("[#{@port}] New Node. Setting as  #{@SLAVE_STATE}")
          end
        when @MASTER_STATE
          if master?
            state_update = StatusChange::NO_CHANGE
            log.info("[#{@port}] Node staying as master")
          else
            state_update = StatusChange::DEMOTED
            log.info("[#{@port}] Node demoted from #{@MASTER_STATE} -> #{@SLAVE_STATE}")
          end
        when @SLAVE_STATE
          if master?
            state_update = StatusChange::PROMOTED
            log.info("[#{@port}] FAILOVER. Promoting node to #{@MASTER_STATE}")
          else
            state_update = StatusChange::NO_CHANGE
            log.info("[#{@port}] Node staying as slave")
            if @previous_leader != @leader
              state_update = StatusChange::DEMOTED
              log.info("[#{@port}] New master is elected so demoting it")
            end
          end
        else
          state_update = StatusChange::NO_CHANGE
          log.error "[#{@port}] Invalid node state!"
        end
        return state_update
      end

      def last_failover
        begin
          node = @zk.get("#{@failover_path}")
          last_modified = node[1].last_modified_time
          return Time.now.to_i - last_modified / 1000
        rescue
          log.info("Not failed over yet")
          @zk.create("#{@failover_path}", :data => '')
          return -1
        end
      end

      def discover
        @previous_leader = @leader
        @leader = elect_leader            
        node = @zk.get("#{@path}/#{@leader}")
        @master_node = JSON.parse(node[0])
        log.debug("Master node: #{@master_node}")
      end

      def watch
        @watcher.unsubscribe if defined? @watcher
        @watcher = @zk.register(@path, &watcher_callback)
      end

      def watcher_callback
        @callback ||= Proc.new do |event|
          # Set new watcher, since ZK watchers are one-shot handlers to aviod races
          watch
          # discover a leader
          discover
          # perform action
          action
        end
      end

      def elect_leader
        begin
          children = @zk.children(@path, :watch => true)
          log.debug("children #{children}")
          children = children.sort { |x, y| Integer(x.gsub(/^.*-(0)*/, '')) <=> Integer(y.gsub(/^.*-(0)*/, '')) }
          return children.first
        rescue Exception => e
          log.error("Exception: #{e}")
        end
      end

      #TODO: allow variable arguement list: only take 2 of 4 now
      def notify(*args)
        log.info("notify stub called")
        @email.send_email(args[0], args[1])
      end
    end

    WATCHERS ||= {}
    WATCHERS['base'] = BaseWatcher

  end
end
