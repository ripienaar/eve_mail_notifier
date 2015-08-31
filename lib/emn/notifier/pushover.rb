require 'pushover'

class EMN
  class Notifier
    class Pushover
      attr_reader :config, :logger, :debug

      def initialize(config, debug=false)
        @config = config
        @logger = config.logger
        @debug = debug
      end

      def api
        ::Pushover.user = config[:pushover][:user_token]
        ::Pushover.token = config[:pushover][:app_token]
        ::Pushover
      end

      def publish(message, subject)
        if debug
          logger.debug("Would have published the message: ")
          puts message
          return true
        else
          responce = api.notification(:html => 1, :title => subject, :message => message)

          if responce.code == 200
            return true
          else
            STDERR.puts("Failed to notify pushover: %s" % responce.inspect)
            return false
          end
        end
      end
    end
  end
end
