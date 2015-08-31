class EMN
  class Monitor
    class Mail
      attr_reader :config, :logger, :api

      def initialize(config)
        @config = config
        @logger = config.logger
        @api = EveAPI.new(config)
      end

      def seen
        @seen ||= {:mail => config.seen.fetch(:mail, {})}
      end

      def notifications
        notifications = {
          :template => "templates/mail.erb",
          :subject => "Eve Mail",
          :seen => config.seen,
          :data => {}
        }

        api.characters.each do |toon|
          logger.debug("Checking character %s" % toon.name)

          messages = api.mails(toon)

          logger.debug("Found %d messages for %s" % [messages.size, toon.name])

          messages.each do |mail|
            logger.debug("Processing email %s: from: %s subject: %s" % [mail.messageID, mail.senderName, mail.title])

            seen[:mail][toon.name] ||= "0"

            if seen[:mail][toon.name] < mail.messageID
              seen[:mail][toon.name] = mail.messageID

              if mail.senderName == toon.name
                logger.debug("Skipping mail %s as it's from the character" % mail.messageID)
                next
              end

              logger.debug("Adding email %s: %s to the queue" % [mail.messageID, mail.title])

              notifications[:data][toon.name] ||= []
              notifications[:data][toon.name] << {
                :id => mail.messageID,
                :from => mail.senderName,
                :date => mail.sentDate,
                :subject => mail.title
              }
            else
              logger.debug("Skipping email %s: it's been seen before (%s)" % [mail.messageID, seen[:mail][toon.name]])
            end
          end
        end

        notifications[:seen] = seen
        notifications
      end
    end
  end
end
