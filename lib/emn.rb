require 'eaal'
require 'yaml'
require 'pushover'
require 'optparse'
require 'pp'
require 'logger'
require 'emn/version'

class EMN
  OPTIONS = {
    :verbose => false,
    :debug => false,
    :config => File.expand_path("~/.emn"),
    :seen => File.expand_path("~/.emn_seen"),
    :logger => nil
  }

  def logger
    if OPTIONS[:debug] || OPTIONS[:verbose]
      return Logger.new(STDOUT)
    else
      return Logger.new(nil)
    end
  end

  def parse_options
    opt = OptionParser.new

    opt.banner = "New mail notifications for Eve Online"
    opt.separator ""

    opt.on("--debug", "Enable debug mode") do
      OPTIONS[:debug] = true
    end

    opt.on("--verbose", "Verbose logging") do
      OPTIONS[:verbose] = true
    end

    opt.on("--config [CONFIG]", "Config file location (%s)" % OPTIONS[:config]) do |v|
      OPTIONS[:config] = File.expand_path(v)
    end

    opt.on("--seen [SEEN_FILE]", "Seen file location (%s)" % OPTIONS[:seen]) do |v|
      OPTIONS[:seen] = File.expand_path(v)
    end

    opt.separator ""
    opt.separator "http://github.com/ripienaar/emn"

    opt.parse!

    logger.info("emn %s starting with config %s and seen file %s" % [ EMN::VERSION, OPTIONS[:config], OPTIONS[:seen]])
  end

  def config
    @config ||= YAML.load(File.read(File.expand_path(OPTIONS[:config])))
  end

  def seen
    @seen ||= YAML.load(File.read(File.expand_path(OPTIONS[:seen])))
  rescue
    @seen = {}
  end

  def save_seen!
    return if OPTIONS[:debug]

    File.open(File.expand_path(OPTIONS[:seen]), "w") do |file|
      file.puts seen.to_yaml
    end
  end

  def pushover
    Pushover.user = config[:pushover][:user_token]
    Pushover.token = config[:pushover][:app_token]
    Pushover
  end

  def eve_api
    unless EAAL.cache.is_a?(EAAL::Cache::FileCache)
      EAAL.cache = EAAL::Cache::FileCache.new
    end

    @eve_api ||= EAAL::API.new(
      config[:eve][:key_id],
      config[:eve][:verification_code]
    )
  end

  def mails(char)
    eve_api.scope = "char"
    eve_api.MailMessages("characterID" => char.characterID).messages.sort_by{|m| m.messageID}
  end

  def characters
    eve_api.scope = "account"
    eve_api.Characters.characters
  end

  def check_mail
    notifications = {}

    characters.each do |toon|
      logger.debug("Checking character %s" % toon.name)

      messages = mails(toon)

      logger.debug("Found %d messages for %s" % [messages.size, toon.name])

      messages.each do |mail|
        logger.debug("Processing email %s: from: %s subject: %s" % [mail.messageID, mail.senderName, mail.title])

        seen[toon.name] ||= "0"

        if seen[toon.name] < mail.messageID
          seen[toon.name] = mail.messageID

          if mail.senderName == toon.name
            logger.debug("Skipping mail %s as it's from the character" % mail.messageID)
            next
          end

          logger.debug("Adding email %s: %s to the queue" % [mail.messageID, mail.title])

          notifications[toon.name] ||= []
          notifications[toon.name] << {
            :from => mail.senderName,
            :date => mail.sentDate,
            :subject => mail.title
          }
        else
          logger.debug("Skipping email %s: it's been seen before (%s)" % [mail.messageID, seen[toon.name]])
        end
      end
    end

    notifications.empty? ? nil : notifications
  end

  def message_body(notifications)
    summary = ["<b>"]
    body = []

    notifications.keys.sort.each do |toon|
      summary << "%s: %d " % [toon, notifications[toon].size]

      body << "<b>%s</b>" % toon
      notifications[toon].reverse[0..config[:max_notifications] - 1].each do |notification|
        body << "  %s: %s" % [notification[:from], notification[:subject]]
      end

      if notifications[toon].size > config[:max_notifications]
        body << "   ... and %d more" % [notifications[toon].size - config[:max_notifications]]
      end

      body << ""
    end

    summary << "</b>"

    [summary, "", body].flatten.join("\n")
  end

  def publish(message)
    if OPTIONS[:debug]
      logger.debug("Would have published the message: ")
      puts message
      return true
    else
      responce = pushover.notification(:html => 1, :message => message)

      if responce.code == 200
        return true
      else
        STDERR.puts("Failed to notify pushover: %s" % responce.inspect)
        return false
      end
    end
  end

  def send!
    if notifications = check_mail
      logger.debug("Found mail for %d characters" % [notifications.keys.size])

      if publish(message_body(notifications))
        save_seen!
      end
    else
      logger.debug("No new mail found, not sending any messages")
    end
  end
end
