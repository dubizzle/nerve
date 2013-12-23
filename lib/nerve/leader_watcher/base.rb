require 'zk'

module Nerve
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

    private

    def elect
      @is_master = false
      leader = leader_election
      if @key == "/#{leader}"
        @is_master = true
      end
    end

    def action
      log.info("I am master? #{@is_master}")
    end

    def watch
      @watcher.unsubscribe if defined? @watcher
      @watcher = @zk.register(@path, &watcher_callback)
    end

    def watcher_callback
      @callback ||= Proc.new do |event|
        # Set new watcher
        watch
        # elect master
        elect
        # perform action
        action
      end
    end

    def leader_election
      begin
        children = @zk.children(@path, :watch => true)
        log.debug("children #{children}")
        children = children.sort { |x, y| Integer(x.gsub(/^.*-(0)*/, '')) <=> Integer(y.gsub(/^.*-(0)*/, '')) }
        return children.first
      rescue Exception => e
        log.error("Exception: #{e}")
      end
    end
  end
end
