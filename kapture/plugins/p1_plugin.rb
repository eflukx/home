require 'serialport'
require 'parse_p1'
require 'json'
require 'measurement_plugin'

module Kapture

  module Plugins

    class P1Reader < MeasurementPlugin

      include Logging

      #
      # start watching the serial device for P1
      #
      def go

          logger.info "starting p1 data logger"

          serial_device = "/dev/ttyUSB0" 
          ser = SerialPort.new(serial_device, 9600, 7, 1, SerialPort::EVEN)

          logger.info "p1 plugin is listening to #{serial_device}"

          buffer = []
          reading_telegram = false
          while true
            c = ser.getc
            
            if c == '/' 
              buffer = []
              reading_telegram = true
            end

            buffer << c if reading_telegram and c != nil

            if c == '!' and reading_telegram
              reading_telegram = false

              p1_telegram_data = buffer.join
              buffer = []

              handle_new_measurement p1_telegram_data
            end
          end
      end

      private 

      #
      # store & publish the new P1 readout 
      # 
      def handle_new_measurement(p1_telegram_data)

        logger.debug "received a new p1 telegram #{p1_telegram_data}"
        
        map = get_measurement_map p1_telegram_data

        store_new_measurement map unless map == nil
        publish_new_measurement map unless map == nil
      end

      #
      # store the measurement in the redis db
      #
      def store_new_measurement(map)

        logger.debug "storing measurement in redis"

        time      = Time.at telegram[:timestamp]
        device_id = telegram[:device_id]

        raw_key     = time.to_i
        by_week_key = time.strftime("%Y/%V")
        by_day_key  = time.strftime("%Y/%j")

        data = telegram.to_json

        @redis.pipelined do
          @redis.zadd "measurement.raw/#{device_id}", raw_key, data
          @redis.hset "measurement.byday/#{device_id}", by_day_key, data
          @redis.hset "measurement.byweek/#{device_id}", by_week_key, data
        end

      end

      #
      # convert the P1 telegram to a simple map
      # 
      def get_measurement_map(p1_telegram_data)

        timestamp = Time.now.to_i

        p1 = ParseP1::Base.new p1_telegram_data
        return nil if !p1.valid? 

        map = {
          :timestamp              => timestamp,
          :device_id              => p1.device_id,
          :electra_import_low     => p1.electra_import_low,
          :electra_import_normal  => p1.electra_import_normal,
          :electra_export_low     => p1.electra_export_low,
          :electra_export_normal  => p1.electra_export_normal,
          :gas_usage              => p1.gas_usage,
          :gas_timestamp          => (p1.last_hourly_reading_gas.to_time - 3600).to_i
        } 

        map if Kultivatr::Telegram::valid? map
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
        map[:electra_export_normal] != nil and
        map[:gas_usage] != nil
      end

    end

  end

end

