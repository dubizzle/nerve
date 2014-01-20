require 'mail'
require_relative 'thread_pool.rb'

module Nerve
  class Email
  include Logging
    def initialize()
      @pool = Pool.new(10)

    end

    def send_email(subject,
                   message,
                   address_from = 'watcher@dubizzle.com',
                   address_to = 'seb@dubizzle.com,qasim@dubizzle.com,aamir@dubizzle.com')
    
        @pool.schedule do
          body = "From: #{address_from}\n\
                  Subject: #{subject}\n\
                  #{message}"
          result = `echo "#{body}" | sendmail "#{address_to}"`
          if $?.exitstatus != 0
            log.error("Failed to send email")
          else
            log.info("Notification email sent to recipients")
        end
    end

    def finailize()
      at_exit { @pool.shutdown }
      log.info('Done with email notify')
    end
  end
end
