require 'zk'

module Nerve
  module LeaderWatcher
    class BaseWatcher
      include Logging

      def initialize(opts={})
        %w{hosts path host}.each do |required|
          raise ArgumentError, "you need to specify required argument #{required}" unless opts[required]
        end

        @hosts = opts['hosts']
        @path = opts['path']
        @host = opts['host']
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

      def action
        log.debug("Am I master? #{master?}")
      end

      private

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

      def notify(*args)
        log.info("notify stub called")
      end
    end

    WATCHERS ||= {}
    WATCHERS['base'] = BaseWatcher

  end
end
