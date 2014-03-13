require_relative 'common'

module Nerve
  module LeaderWatcher
    class PostgreSQLWatcher < BaseWatcher
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
          if new_node_state == StatusChange::STARTUP
            ss = 'master'
            command = "sudo /bin/su - postgres -c '/opt/smartstack/nerve/postgres_master_config.sh'"
          elsif new_node_state == StatusChange::PROMOTED
            ss = 'promoted to master'
            command = "sudo /bin/su - postgres -c 'touch /var/lib/postgresql/9.3/main/postgresql.trigger'"
          else
            ss = 'slave'
            command = "sudo su - postgres -c '/opt/smartstack/nerve/postgres_slave_config.sh #{master_node["host"]} #{master_node["port"]}'"
          end
          log.info "---> Previous State #{state} Is master? #{master?} Port: #{@port} Status: #{new_node_state} Command: #{command}"
          res = `#{command}`
          aa = `echo #{ss} > /tmp/#{@host}_#{@port}.state && echo '#{@host} #{@port} #{Time.now.to_f} #{ss}' >> /tmp/status.log`
          log.info("redis response #{res}")
        end
      end
    end

    WATCHERS ||= {}
    WATCHERS['postgresql'] = PostgreSQLWatcher
  end
end
