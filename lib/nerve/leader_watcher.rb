require_relative "./leader_watcher/base"
require_relative "./leader_watcher/postgresql"

module Nerve
  class LeaderWatcher

    @watchers = {
      'base'=>BaseWatcher,
      'postgresql'=>PostgreSQLWatcher,
    }

    def self.create(opts)
      %w{name hosts path host}.each do |required|
        raise ArgumentError, "you need to specify required argument #{required}" unless opts[required]
      end

      raise ArgumentError, "Invalid service name #{opts['name']}" \
        unless @watchers.has_key?(opts['name'])
      
      return @watchers[opts['name']].new(opts)
    end
  end
end
