require 'nerve/service_watcher/tcp'
require 'nerve/service_watcher/http'
require 'nerve/service_watcher/rabbitmq'
require 'nerve/service_watcher/postgresql'
require 'nerve/service_watcher/mysql'

module Nerve
  class ServiceWatcher
    include Utils
    include Logging

    def initialize(service={})
      log.debug "nerve: creating service watcher object"

      # check that we have all of the required arguments
      %w{name instance_id host port zk_hosts zk_path}.each do |required|
        raise ArgumentError, "missing required argument #{required} for new service watcher" unless service[required]
      end

      @name = service['name']
      @enable_leader_watcher = service.has_key?('leader_watcher')

      # configure the reporter, which we use for talking to zookeeper
      @reporter = Reporter.new({
          'hosts' => service['zk_hosts'],
          'path' => service['zk_path'],
          'key' => "#{service['instance_id']}_#{@name}",
          'data' => {'host' => service['host'], 'port' => service['port']},
          'sequential' => service['sequential'] || false
        })

      if @enable_leader_watcher
        # configure the leader watcher
        @leader_watcher = LeaderWatcher::LeaderWatcherFactory.create({
          'hosts' => service['zk_hosts'],
          'path' => service['zk_path'],
          'type' => service['leader_watcher'],
          'host' => service['host']
        })
      end

      # instantiate the checks for this service
      @service_checks = []
      service['checks'] ||= []
      service['checks'].each do |check|
        check['type'] ||= "undefined"
        begin
          service_check_class = ServiceCheck::CHECKS[check['type']]
        rescue
          raise ArgumentError,
            "invalid service check type #{check['type']}; valid types: #{ServiceCheck::CHECKS.keys.join(',')}"
        end

        check['host'] ||= service['host']
        check['port'] ||= service['port']
        check['name'] ||= "#{@name} #{check['type']}-#{check['host']}:#{check['port']}"
        @service_checks << service_check_class.new(check)
      end

      # how often do we initiate service checks?
      @check_interval = service['check_interval'] || 0.5

      log.debug "nerve: created service watcher for #{@name} with #{@service_checks.size} checks"
    end

    def run()
      log.info "nerve: starting service watch #{@name}"

      # begin by reporting down
      @reporter.start()
      @reporter.report_down
      was_up = false

      until $EXIT
        @reporter.ping?

        # what is the status of the service?
        is_up = check?
        log.debug "nerve: current service status for #{@name} is #{is_up.inspect}"

        if is_up != was_up
          if is_up
            @reporter.report_up
            log.info "nerve: service #{@name} is now up"
            if @enable_leader_watcher
              # pass the full key of current node to elect master
              @leader_watcher.start(@reporter.full_key)
            end
          else
            @reporter.report_down
            log.warn "nerve: service #{@name} is now down"
          end
          was_up = is_up
        end

        # wait to run more checks
        sleep @check_interval
      end
    rescue StandardError => e
      log.error "nerve: error in service watcher #{@name}: #{e}"
      raise e
    ensure
      log.info "nerve: ending service watch #{@name}"
      $EXIT = true
    end

    def check?
      @service_checks.each do |check|
        return false unless check.up?
      end
      return true
    end
  end
end
