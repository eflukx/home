require 'serialport'
require 'parse_p1'
require 'json'

class P1Reader < MeasurementPlugin

  def go
      ser = SerialPort.new("/dev/ttyUSB0", 9600, 7, 1, SerialPort::EVEN)

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

          handle p1_telegram_data
        end
      end
  end

  def handle(p1_telegram_data)
    map = get_measurement_map p1_telegram_data
    new_measurement map unless map == nil
  end

  def get_measurement_map(p1_telegram_data)

    timestamp = Time.now.to_i

    p1 = ParseP1::Base.new p1_telegram_data
    raise "invalid p1 data" if !p1.valid? 

    data = {
      :timestamp              => timestamp,
      :device_id              => p1.device_id,
      :electra_import_low     => p1.electra_import_low,
      :electra_import_normal  => p1.electra_import_normal,
      :electra_export_low     => p1.electra_export_low,
      :electra_export_normal  => p1.electra_export_normal,
      :gas_usage              => p1.gas_usage,
      :gas_timestamp          => (p1.last_hourly_reading_gas.to_time - 3600).to_i
    } 

    data if Kultivatr::Telegram::valid? data
  end

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
