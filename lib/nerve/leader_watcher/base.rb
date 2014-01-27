require 'zk'
require_relative '../common'
require_relative '../email'

module Nerve
  module LeaderWatcher
    class BaseWatcher
      include Logging

      def initialize(opts={})
        %w{hosts path host failover_path}.each do |required|
          raise ArgumentError, "you need to specify required argument #{required}" unless opts[required]
        @email = Email::new
      end

        @hosts = opts['hosts']
        @path = opts['path']
        @host = opts['host']
        @port = opts['port']
        @failover_path = opts['failover_path']
        @SLAVE_STATE = 'slave'
        @MASTER_STATE = 'master'
        @FAILOVER_INTERVAL = opts['failover_interval']
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

      def failover
        last_state = previous_state
        new_node_state = node_state_update
        should_failover = last_state == @SLAVE_STATE && master ? true : false

        if should_failover
            if last_failover > @FAILOVER_INTERVAL
                log.info("Should failover")
                return true
            else
                log.info("Failing over too often. Not going to.")
                return false
        end

      private

      def action
        log.debug("Am I master? #{master?}")
      end


      def previous_state
        begin
          file = File.open("#{Dir.home}/pg.state")
          state = file.gets
        rescue
          log.info("Failed to open state file assuming new node")
          state = ''
        end
        return state
      end

      def node_state_update
          case previous_state
            when ''
                if master?
                    state_update = StatusChange::PROMOTED
                    log.debug("New Node. Setting as  #{@MASTER_STATE}")
                else
                    state_update = StatusChange::DEMOTED
                    log.debug("New Node. Setting as  #{@SLAVE_STATE}")
            when @MASTER_STATE
                if master?
                    state_update = StatusChange::NO_CHANGE
                    log.info("Node staying as master")
                else
                    state_update = StatusChange::DEMOTED
                    log.info("Node demoted from #{@MASTER_STATE} -> #{@SLAVE_STATE}")
            when @SLAVE_STATE
                if master?
                    state_upate = StatusChange::PROMOTED
                    log.error("FAILOVER. Prompting node to #{@MASTER_STATE}")
                else
                    state_update = StatusChange::NO_CHANGE
                    log.info("Node demoted from #{@MASTER_STATE} -> #{@SLAVE_STATE}")

      def last_failover
        begin
            node = @zk.get("#{failover_path}")
            last_modified = node[1].last_modified_time
            return Time.now.to_i - last_modified / 1000
        rescue
            log.info("Not failed over yet")
            return -1

      def discover
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
        email.send_email(args[0], args[1])
      end
    end

    WATCHERS ||= {}
    WATCHERS['base'] = BaseWatcher

  end
end
