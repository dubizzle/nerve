require 'zk'

module Nerve
  module LeaderWatcher
    class PostgreSQLWatcher < BaseWatcher
      include Logging
      
      private
      def action
        log.info("Am I master? #{master?}")
        log.info("Hello! #{master_node}")
        if master?
          res = `sudo /bin/su - postgres -c /opt/smartstack/nerve/postgres_master_config.sh`
        else
          res = `sudo su - postgres -c "/opt/smartstack/nerve/postgres_slave_config.sh #{master_node["host"]} #{master_node["port"]}"`
        end
        log.info(res)
      end
    end
    
    WATCHERS ||= {}
    WATCHERS['postgresql'] = PostgreSQLWatcher
  end
end
