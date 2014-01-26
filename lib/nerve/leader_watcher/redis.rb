module Nerve
  module LeaderWatcher
    class RedisWatcher < BaseWatcher
      include Logging

      def initialize(opts={})
        %w{hosts path host port service_home}.each do |required|
          raise ArgumentError, "you need to specify required argument #{required}" unless opts[required]
        end

        @hosts = opts['hosts']
        @path = opts['path']
        @host = opts['host']
        @port = opts['port']
        @service_home = opts['service_home']
      end

      private
      def action
        log.info("Am I master? #{master?}")
        if master?
          command = "sudo su - vagrant -c  '/opt/smartstack/nerve/redis_master_config.sh #{@service_home} #{@host} #{@port}'"
        else
          command = "sudo su - vagrant -c  '/opt/smartstack/nerve/redis_slave_config.sh #{@service_home} #{master_node["host"]} #{master_node["port"]} #{@host} #{@port}'"
        end
        log.debug "#{command}"
        res = `#{command}`
        log.info("redis response #{res}")
      end
    end

    WATCHERS ||= {}
    WATCHERS['redis'] = RedisWatcher
  end
end
