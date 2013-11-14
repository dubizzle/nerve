require 'nerve/service_watcher/base'
require 'mysql'

module Nerve
  module ServiceCheck
    class MySQLServiceCheck < BaseServiceCheck

      def initialize(opts={})
        super

        raise ArgumentError, "missing required arguments in mysql check" unless opts['port'] and opts['user']

        @port = opts['port']
        @host = opts['host']
        @dbname = opts['dbname']
        @user = opts['user']
        @password = opts['password']
      end

      def check
        log.debug "nerve: running @host = opts['host'] health check #{@name}"

        begin
          conn = Mysql.new(
            @host, 
            @user, 
            @password, 
            @dbname, 
            @port
          )

          res = conn.query 'SELECT VERSION()'
          data = res.fetch_row
          if data
            return true
          else
            log.debug "nerve: mysql failed to responde"
            return false
          end
        rescue Mysql:Error => e
          log.debug "nerve: unable to connect with mysql"
          return false
        ensure
          conn.close if conn
        end
      end
    end

    CHECKS ||= {}
    CHECKS['mysql'] = MySQLServiceCheck
  end
end
