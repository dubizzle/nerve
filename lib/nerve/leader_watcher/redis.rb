require_relative 'common'

module Nerve
  module LeaderWatcher
    class RedisWatcher < BaseWatcher
      include Logging

      private
      def action
        state = previous_state
        if terminate_failover(state)
            log.info("Not failing over")
            notify("Not Failing over", "Failover time less than interval. Something is wrong!")
            return
        end

        new_node_state = node_state_update(state)
        if new_node_state != StatusChange::NO_CHANGE
          if new_node_state == StatusChange::PROMOTED
            ss = 'master'
            command = "sudo su - vagrant -c  '/opt/smartstack/nerve/redis_master_config.sh #{@service_home} #{@host} #{@port}'"
          else
            ss = 'slave'
            command = "sudo su - vagrant -c  '/opt/smartstack/nerve/redis_slave_config.sh #{@service_home} #{master_node["host"]} #{master_node["port"]} #{@host} #{@port}'"
          end
          log.info "---> Previous State #{state} Is master? #{master?} Port: #{@port} Status: #{new_node_state} Command: #{command}"
          res = `#{command}`
          aa = `echo #{ss} > /tmp/#{@host}_#{@port}.state && echo '#{@host} #{@port} #{Time.now.to_f} #{ss}' >> /tmp/status.log`
          log.info("redis response #{res}")
        end
      end
    end

    WATCHERS ||= {}
    WATCHERS['redis'] = RedisWatcher
  end
end
