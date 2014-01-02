require 'zk'

module Nerve
	module LeaderWatcher
	  class PostgreSQLWatcher < BaseWatcher
	    include Logging
	    
	    private
	    def action
	      log.info("Am I master? #{master?}")
	    end
	  end

	  WATCHERS ||= {}
	  WATCHERS['postgresql'] = PostgreSQLWatcher
  end
end
