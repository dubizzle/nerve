require_relative 'common'

module Nerve
  module LeaderWatcher
    class RedisWatcher < BaseWatcher
      include Logging

      private
      def action
        log.info("Am I master? #{master?}")
        
        if !failover
            log.info("Not failing over")
            notify("Not Failing over", "Failover time less than interval. Something is wrong!")
            return
        end

        if new_node_state != StatusChange::NO_CHANGE
          if new_node_state == StatusChange::PROMOTED
            command = "sudo su - vagrant -c  '/opt/smartstack/nerve/redis_master_config.sh #{@service_home} #{@host} #{@port}'"
          else
            command = "sudo su - vagrant -c  '/opt/smartstack/nerve/redis_slave_config.sh #{@service_home} #{master_node["host"]} #{master_node["port"]} #{@host} #{@port}'"
          end
          log.debug "#{command}"
          res = `#{command}`
          log.info("redis response #{res}")
        end
      end
    end

    WATCHERS ||= {}
    WATCHERS['redis'] = RedisWatcher
  end
end
