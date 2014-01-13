module Kapture

  require 'json'
  require 'active_support/core_ext/hash'
  require 'eventmachine'
  require 'i2c'

  module Plugins

    class DS7505 < MeasurementPlugin

      include Logging

      attr_reader :redis

      def initialize
        @redis = Redis.new
      end

      #
      # start pulling data from the i2c bus
      #
      def go!

        logger.info "starting ds7505 compatible temperature logger"

        i2c_device = "/dev/i2c-1" 
        i2c_device_address = 0x4f
        ds75_device = I2C.create(i2c_device)
        
        polling_interval = 60 #seconds
        device_id = "ds7505_4f"

        logger.info "ds7505 temerature plugin polling every #{polling_interval} second(s) on bus: #{i2c_device}, address: #{i2c_device_address}"

        EventMachine.run {
          EventMachine.add_periodic_timer(polling_interval) {
            measured_temperature = ds75_device.read(i2c_device_address,2,0).unpack("s>")[0]/256.0
            handle_new_measurement ({:timestamp => Time.now.to_i, :device_id => device_id, :type => "Celcius", :value => measured_temperature})
          }
        }
      end

      private 

      def handle_new_measurement(measurement_data)
        publish_current_measurement measurement_data
        store_new_measurement measurement_data
      end

      def publish_current_measurement(measurement_data)
        logger.debug "publishing current temperature for #{measurement_data[:device_id]}"
        message = measurement_data.to_json
        @redis.publish :new_measurement, message
      end

      def store_new_measurement(measurement_data)
        logger.debug "storing measurement in Redis (#{measurement_data[:value]} graden)"

        time      = Time.at measurement_data[:timestamp]
        device_id = measurement_data[:device_id]

        raw_key     = time.to_i
        by_week_key = time.strftime("%Y/%V")
        by_day_key  = time.strftime("%Y/%j")

        transformed_data =->(timestamp_key, measurement_key) {
         {
            :timestamp  => measurement_data[timestamp_key] * 1000,
            :value      => measurement_data[measurement_key]
          }.to_json
        }

        store_measurement =->(key, data){
            @redis.zadd "ds7505:#{device_id}:#{key}:raw", raw_key, data
            @redis.hset "ds7505:#{device_id}:#{key}:byday", by_day_key, data
            @redis.hset "ds7505:#{device_id}:#{key}:byweek", by_week_key, data
        }

        @redis.pipelined do
#          keys = [:temperature]
#          keys.map{|e| store_measurement.(e, transformed_data.(:timestamp,:value))}

          store_measurement.(:temperature, transformed_data.(:timestamp,:value))          
        end
        
      end

    end
  end
end

