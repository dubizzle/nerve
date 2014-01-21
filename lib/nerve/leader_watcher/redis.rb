module Nerve
  module LeaderWatcher
    class RedisWatcher < BaseWatcher
      include Logging

      private
      def action
        log.info("Am I master? #{master?}")
        log.info("Hello! #{master_node}")
        if master?
          res = `echo "master"`
        else
          res = `echo "slave"`
        end
        log.info(res)
      end
    end

    WATCHERS ||= {}
    WATCHERS['redis'] = RedisWatcher
  end
end
