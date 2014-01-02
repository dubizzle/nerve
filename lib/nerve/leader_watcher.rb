require_relative "./leader_watcher/base"
require_relative "./leader_watcher/postgresql"

module Nerve
  module LeaderWatcher
    class LeaderWatcherFactory

      def self.create(opts)
        %w{name hosts path host}.each do |required|
          raise ArgumentError, "you need to specify required argument #{required}" unless opts[required]
        end

        raise ArgumentError, "Invalid service name #{opts['name']}" \
          unless WATCHERS.has_key?(opts['name'])
        
        return WATCHERS[opts['name']].new(opts)
      end
    end
  end
end
