class EMN
  class EveAPI
    attr_reader :config, :logger

    def initialize(config)
      @config = config
      @logger = config.logger
    end

    def api
      unless EAAL.cache.is_a?(EAAL::Cache::FileCache)
        EAAL.cache = EAAL::Cache::FileCache.new
      end

      @api ||= EAAL::API.new(
        config[:eve][:key_id],
        config[:eve][:verification_code]
      )
    end

    def planets(char)
      api.scope = "char"
      api.PlanetaryColonies("characterID" => char.characterID).colonies.sort_by{|c| c.planetID}
    end

    def planet_pins(char, planet)
      api.scope = "char"
      api.PlanetaryPins("characterID" => char.characterID, "planetID" => planet.planetID).pins.sort_by do |pin|
        pin.pinID
      end.map do |pin|
        pin.expiryTime = Time.parse("%s UTC" % pin.expiryTime)
        pin.lastLaunchTime = Time.parse("%s UTC" % pin.lastLaunchTime)
        pin.installTime = Time.parse("%s UTC" % pin.installTime)
        pin
      end
    end

    def mails(char)
      api.scope = "char"
      api.MailMessages("characterID" => char.characterID).messages.sort_by{|m| m.messageID}
    end

    def characters
      api.scope = "account"
      api.Characters.characters
    end
  end
end
