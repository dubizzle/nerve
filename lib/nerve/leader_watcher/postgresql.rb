require 'zk'
require_relative '../common'

module Nerve
  module LeaderWatcher
    class PostgreSQLWatcher < BaseWatcher
      include Logging
      
      private
      def action
        log.info("Am I master? #{master?} last state: #{last_state}")
        log.info("Hello! #{master_node}")
  
        if !failover
            log.info("Not failing over")
            notify("Not Failing over", "Failover time less than interval. Something is wrong!")
            return

        if new_node_state != StatusChange::NO_CHANGE
          if new_node_state == StatusChange::PROMOTED
            res = `sudo /bin/su - postgres -c /opt/smartstack/nerve/postgres_master_config.sh`
          else
            res = `sudo su - postgres -c "/opt/smartstack/nerve/postgres_slave_config.sh #{master_node["host"]} #{master_node["port"]}"`
          end
          log.info(res)
        end
      end

   end
    
    WATCHERS ||= {}
    WATCHERS['postgresql'] = PostgreSQLWatcher
  end
end
