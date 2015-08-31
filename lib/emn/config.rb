class EMN
  class Config
    def initialize(config="~/.emn", seen="~/.emn_seen")
      @config_file = config
      @seen_file = seen

      load_config
    end

    def logger
      if OPTIONS[:debug] || OPTIONS[:verbose]
        return @logger ||= Logger.new(STDOUT)
      else
        return @logger ||= Logger.new(nil)
      end
    end

    def seen
      YAML.load(File.read(File.expand_path(@seen_file)))
    rescue
      {}
    end

    def save_seen!(seen)
      return if OPTIONS[:debug]

      File.open(File.expand_path(@seen_file), "w") do |file|
        file.puts seen.to_yaml
      end
    end

    def [](key)
      @config[key]
    end

    def load_config
      @config = YAML.load(File.read(File.expand_path(@config_file)))
    end
  end
end
