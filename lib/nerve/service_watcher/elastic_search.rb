require 'nerve/service_watcher/base'
require 'elasticsearch'

module Nerve
  module ServiceCheck
    class ElasticSearchServiceCheck < BaseServiceCheck

      def initialize(opts={})
        super

        @host = opts['host'] || '127.0.0.1'
        @port = opts ['port'] || 6379
        @db = opts['db'] || 0
        @name = "#{@db}@#{@host}:#{@port}"
      end

      def check
        log.debug "nerve: running elastic_search @host = #{@host} health check #{@name}"

        begin
          #redis = Redis.new(:host => @host, :port => @port, :db => @db)
          client = Elasticsearch::Client.new log: true

          res = client.cluster.health

          #todo
          if res.eql? 'PONG'
            return true
          else
            log.info "nerve: elastic_search #{@name} failed to respond"
            return false
          end
        rescue Exception => e #todo
          log.info "nerve: unable to connect to elastic_search #{@name} #{e}"
          return false
        ensure
          redis.quit if redis
        end
      end
    end

    CHECKS ||= {}
    CHECKS['elastic_search'] = ElasticSearchServiceCheck
  end
end
