module Kapture

  require 'json'
  require 'active_support/core_ext/hash'
  require 'serialport'
  require 'parse_p1'
  require 'time_difference'
  require 'eventmachine'

  module Plugins

    class P1Reader < MeasurementPlugin

      include Logging

      def initialize
        @redis = Redis.new

        config_file = File.dirname(__FILE__) + '/../../../config/p1_plugin.yml'
        @config = YAML::load(File.open(config_file))
      end

      def p1_reader
        @p1_reader ||= SerialPort.new(@config["serial_device"], 9600, 7, 1, SerialPort::EVEN)
      end

      #
      # start watching the serial device for P1
      #
      def go!

          logger.info "starting p1 data logger"
          logger.info "config: #{@config}"

          EventMachine::run {

            telegram = wait_for_telegram
            handle_new_telegram telegram

          }

          logger.info "p1 is shutting down"
      end

      private 

      def wait_for_telegram

          buffer = nil

          while true  
            c = p1_reader.getc
            
            if c == '/' 
              buffer = []
            end

            buffer << c unless buffer == nil or c == nil

            if c == '!' and buffer != nil
              return buffer.join
            end
          end

      end

      #
      # store & publish the new P1 readout 
      # 
      def handle_new_telegram(p1_telegram_data)
        logger.debug "received a new p1 telegram"

        map = get_measurement_map p1_telegram_data
        if(map == nil or valid?(map) == false)
          logger.warn "invalid telegram received #{p1_telegram_data}"
          return
        end

        publish_current_energy_consumption map
        store_new_measurement map
      end

      #
      # publish a message with the current energy consumption
      #
      def publish_current_energy_consumption(measurement_data)

        logger.debug "publishing current energy consumption"

        message = {
          :timestamp  => measurement_data[:timestamp],
          :device_id  => measurement_data[:device_id],
          :type       => "current_energy_usage",
          :value      => measurement_data[:current_energy_usage]
        }.to_json

        @redis.publish :new_measurement, message
      end

      #
      # Check if there is a previous measurment
      # and calculate the delta between them 
      #
      def store_new_measurement(current_measurement)

        if @previous_measurement == nil
          @previous_measurement = current_measurement
          return
        end

        delta = calculate_delta @previous_measurement, current_measurement
        save_measurement_to_redis delta

        @previous_measurement = current_measurement
      end

      #
      # calculate the delta in Watt between two measurements in kWh
      #
      def calculate_delta(previous, current)

        kwh_to_watts = 1 / (TimeDifference.between(previous[:timestamp], current[:timestamp]).in_seconds / 3600) * 1000

        delta =->(member) { 
         a = current[member]
         b = previous[member]
         return (a - b) unless a == nil or b == nil
        }

        measurement = {
          :timestamp             => current[:timestamp],
          :device_id             => current[:device_id],
          :electra_import_low    => delta.(:electra_import_low) * kwh_to_watts,
          :electra_import_normal => delta.(:electra_import_normal) * kwh_to_watts,
          :electra_export_low    => delta.(:electra_export_low) * kwh_to_watts,
          :electra_export_normal => delta.(:electra_export_normal) * kwh_to_watts
        }

      end

      #
      # store the (delta) measurement in redis
      #
      def save_measurement_to_redis(measurement_data)

        raise "invalid measurement data" if !valid? measurement_data

        logger.debug "storing measurement in redis"

        data =->(measurement_key) {
         {
            :timestamp  => measurement_data[:timestamp] * 1000,
            :value      => measurement_data[measurement_key]
          }.to_json
        }

        device_id = measurement_data[:device_id]

        @redis.pipelined do

          #
          # store energy measuments
          #

          score = measurement_data[:timestamp]
          keys = [:electra_import_low, :electra_import_normal,
                  :electra_export_low, :electra_export_normal]
          
          keys.each do |key| 
            result = data.(key)
            
            logger.debug "storing #{key} -> #{result}"
            @redis.zadd "p1:#{device_id}:#{key}:raw", score, result
          end

        end

      end

 #         @redis.hset "p1:#{measurement_data[:gas_device_id]}:#{key}:byday", by_day_key, data.(:timestamp, key)
 #         @redis.hset "p1:#{measurement_data[:gas_device_id]}:#{key}:byweek", by_week_key, data.(:timestamp, key)


      #
      # convert the P1 telegram to a simple map
      # 
      def get_measurement_map(p1_telegram_data)

        p1 = ParseP1::Base.new p1_telegram_data

        if(!p1.valid?)
          logger.warn "invalid telegram found #{p1_telegram_data}}"
          return nil
        end

        {
          :timestamp              => Time.now.to_i,
          :device_id              => p1.device_id,
          :electra_import_low     => p1.electra_import_low,
          :electra_import_normal  => p1.electra_import_normal,
          :electra_export_low     => p1.electra_export_low,
          :electra_export_normal  => p1.electra_export_normal,
          :current_energy_usage   => p1.actual_electra
        } 

      end

      #
      # validate the readout
      # 
      def valid?(map)
        map[:timestamp] != nil and
        map[:device_id] != nil and
        map[:electra_import_low] != nil and
        map[:electra_import_normal] != nil and 
        map[:electra_export_low] != nil and
        map[:electra_export_normal] != nil
      end

    end
  end
end

