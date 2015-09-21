require 'eaal'
require 'yaml'
require 'optparse'
require 'pp'
require 'logger'
require 'emn/version'
require 'emn/config'
require 'emn/eve_api'
require 'emn/monitor/mail'
require 'emn/monitor/pi'
require 'emn/notifier/pushover'
require 'tilt/erb'

class EMN
  OPTIONS = {
    :verbose => false,
    :debug => false,
    :config => File.expand_path("~/.emn"),
    :seen => File.expand_path("~/.emn_seen"),
    :checkers => []
  }

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

    opt.on("--pi", "Check PI extractor cycles") do
      OPTIONS[:checkers] << EMN::Monitor::Pi
    end

    opt.on("--mail", "Check for new emails") do
      OPTIONS[:checkers] << EMN::Monitor::Mail
    end

    opt.separator ""
    opt.separator "http://github.com/ripienaar/emn"

    opt.parse!

    if OPTIONS[:checkers].empty?
      abort("Please specify either --mail, --pi or both")
    end
  end

  def logger
    config.logger
  end

  def config
    @config ||= EMN::Config.new(OPTIONS[:config], OPTIONS[:seen])
  end

  def pushover
    @pushover_api ||= Notifier::Pushover.new(config, OPTIONS[:debug])
  end

  def eve_api
    @eve_api ||= EveAPI.new(config)
  end

  def process!
    OPTIONS[:checkers].each do |klass|
      checker = klass.new(config)
      logger.debug("Processing %s" % checker.class)

      notifications = checker.notifications

      if !notifications[:data].empty?
        template_file = File.expand_path(File.join(File.dirname(__FILE__), "..", notifications[:template]))
        logger.debug("Sending notifications using template %s" % template_file)

        template = Tilt::ERBTemplate.new(template_file)
        output = template.render(:data => notifications[:data], :config => config)

        if pushover.publish(output, notifications[:subject])
          config.save_seen!(config.seen.merge(notifications[:seen]))
        end
      else
        config.save_seen!(config.seen.merge(notifications[:seen]))
      end
    end
  rescue EAAL::Exception::EveAPIException
    STDERR.puts("Failed to communicate with the EVE API: %s: %s: %s" % [$!.class, caller.first, $!.to_s])
    exit 1
  end
end
