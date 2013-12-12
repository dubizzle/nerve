require 'nerve/service_watcher/base'
require 'riak'

module Nerve
  module ServiceCheck
    class RiakServiceCheck < BaseServiceCheck

      def initialize(opts={})
        super

        @host = opts['host'] || '127.0.0.1'
        @port = opts ['http_port'] || 8098
        @name = "#{@host}:#{@port}"
      end

      def check
        log.debug "nerve: running @host = #{@host} health check #{@name}"

        riak = Riak::Client.new(:host => @host, :http_port => @port)

        if riak.ping
          return true
        else
          log.info "nerve: riak #{@name} failed to respond"
          return false
        end
      end
    end

    CHECKS ||= {}
    CHECKS['riak'] = RiakServiceCheck
  end
end
