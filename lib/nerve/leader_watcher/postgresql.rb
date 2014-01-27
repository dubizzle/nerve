require 'zk'
require_relative '../email'
require_relative '../common'

module Nerve
  module LeaderWatcher
    class PostgreSQLWatcher < BaseWatcher
      include Logging
      
      def initialize
          @email = Email::new
      end

      def notify(*args)
          email.send_email(args[0], args[1])
      end
  
      private
      def action
        log.info("Am I master? #{master?} last state: #{last_state}")
        log.info("Hello! #{master_node}")
  
        last_state = previous_state
        new_node_state = node_state_update
        failover = last_state == @SLAVE_STATE && master ? True : False

        if failover
            log.error("Failing over")
        end

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
