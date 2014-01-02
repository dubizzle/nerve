require 'zk'

module Nerve
	module LeaderWatcher
	  class PostgreSQLWatcher < BaseWatcher
	    include Logging
	    
	    private
	    def action
	      log.info("I am master? #{@is_master}")
	    end
	  end

	  WATCHERS ||= {}
	  WATCHERS['postgresql'] = PostgreSQLWatcher
  end
end
