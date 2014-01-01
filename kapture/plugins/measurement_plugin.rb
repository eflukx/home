module Kapture

  module Plugins

    require 'redis'
    require './lib/plugin'

    class MeasurementPlugin
      include Plugin

      attr_reader redis

      def initialize
      	@redis = Redis.new
      end

      def go
        raise NotImplementedError.new('OH NOES!')
      end

      def new_measurement(measurement_data)

      	puts "received #{measurement_data}"

      	@redis.publish :new_measurement, measurement_data
      end
    end

  end
end