require 'zk'

module Nerve
  class PostgreSQLWatcher < BaseWatcher
    include Logging
    
    private
    def action
      log.info("I am master? #{@is_master}")
    end
  end
end
