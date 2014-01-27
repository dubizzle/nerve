require_relative "./leader_watcher/base"
require_relative "./leader_watcher/postgresql"

module Nerve
  module LeaderWatcher
    class LeaderWatcherFactory

      def self.create(opts)
        %w{type hosts path host port}.each do |required|
          raise ArgumentError, "you need to specify required argument #{required}" unless opts[required]
        end

        raise ArgumentError, "Invalid watcher type #{opts['type']}" \
          unless WATCHERS.has_key?(opts['type'])
        
        return WATCHERS[opts['type']].new(opts)
      end
    end
  end
end
