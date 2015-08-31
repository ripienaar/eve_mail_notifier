require 'time'

class EMN
  class Monitor
    class Pi
      attr_reader :config, :logger, :api

      def initialize(config)
        @config = config
        @logger = config.logger
        @api = EveAPI.new(config)
      end

      def seen
        @seen ||= {:planets => config.seen.fetch(:planets, {})}
      end

      def seconds_to_human(seconds)
        if seconds < 0
          past = true
          seconds = seconds.abs
        end

        days = seconds.to_i / 86400
        seconds -= 86400 * days

        hours = seconds.to_i / 3600
        seconds -= 3600 * hours

        minutes = seconds.to_i / 60
        seconds -= 60 * minutes

        time = if days > 1
          "%d days %d hours %d minutes" % [days, hours, minutes]
        elsif days == 1
          "%d day %d hours %d minutes" % [days, hours, minutes]
        elsif hours > 0
          "%d hours %d minutes" % [hours, minutes]
        elsif minutes > 0
          "%d minutes" % [minutes]
        else
          "%d seconds" % [seconds]
        end

        past ? "%s ago" % time : time
      end

      def pins
        api.characters.each do |toon|
          logger.debug("Processing toon %s" % toon.name)
          api.planets(toon).each do |planet|
            logger.debug("Processing planet %s" % planet.planetName)
            api.planet_pins(toon, planet).sort_by{|p| p.planetName}.each do |pin|
              yield(toon, planet, pin)
            end
          end
        end
      end

      def notifications
        notifications = {
          :template => "templates/pi.erb",
          :subject => "Eve PI",
          :data => {}
        }

        pins do |toon, planet, pin|
          next if pin.expiryTime.year == 1

          time_till_expire = pin.expiryTime - Time.now.utc
          logger.debug("%s expires in %s / %s (%s)" % [planet.planetName, time_till_expire, seconds_to_human(time_till_expire), pin.expiryTime])

          seen[:planets][toon.name] ||= {}

          if (time_till_expire < 600) && (time_till_expire > -86400)
            if seen[:planets][toon.name][planet.planetName]
              next
            else
              seen[:planets][toon.name][planet.planetName] = true
            end

            notifications[:data][toon.name] ||= []
            notifications[:data][toon.name] << {
              :name => planet.planetName,
              :time_till_expire => seconds_to_human(time_till_expire),
              :expire_time => pin.expiryTime
            }
          else
            seen[:planets][toon.name].delete(planet.planetName)
          end
        end

        notifications[:seen] = seen
        notifications
      end
    end
  end
end
