#!/usr/bin/env ruby

require 'parse_p1'
require 'json'
require 'time_difference'

def read_telegram_and_timestamp(file_name)
	{
		:timestamp => DateTime.strptime(File.basename(file_name, '.*'), "%Y%m%d-%H%M%S"),
		:telegram => ParseP1::Base.new(File.read(file_name))
	}
end

def normalize_electra(current, previous)

	start_time = previous[:timestamp].to_time
	end_time = current[:timestamp].to_time
	to_watts = 1 / (TimeDifference.between(start_time, end_time).in_seconds / 3600) * 1000

	calculate =->(symbol) { 
		a = current[:telegram].send(symbol)
		b = previous[:telegram].send(symbol)
		return (a - b) * to_watts unless a == nil or b == nil
	}
	
	{
	 :timestamp 			=> current[:timestamp],
	 :electra_import_low 	=> calculate.(:electra_import_low),
	 :electra_import_normal => calculate.(:electra_import_normal),
	 :electra_export_low 	=> calculate.(:electra_export_low),
	 :electra_export_normal => calculate.(:electra_export_normal),
	}
end

def normalize_gas(current, previous)

	calculate =->(symbol) { 
		a = current[:telegram].send(symbol)
		b = previous[:telegram].send(symbol)
		return (a - b) unless a == nil or b == nil
	}

	{
	 :timestamp 	=> current[:timestamp],
	 :gas_usage 	=> calculate.(:gas_usage),
	}
end


file_names = Dir["data-logger/*.txt"]

values = file_names.map(&method(:read_telegram_and_timestamp)).select{ |e| e[:telegram].valid? }
grouped_values = values.group_by{ |e| e[:timestamp].to_i / (10 * 60) }

electra_values = grouped_values.keys.map{ |e| grouped_values[e].last }
gas_values = values.uniq{|e| e[:telegram].last_hourly_reading_gas}

electra = electra_values.drop(1).map.with_index { |current,index| normalize_electra(current, electra_values[index]) }
gas 	= gas_values.drop(1).map.with_index { |current,index| normalize_gas(current, gas_values[index]) }

time_and_measurement =->(entry, symbol) { 
	[ entry[:timestamp].to_i * 1000, entry[symbol] ] 
}

electra_series = {

	:title => "Power consumption",
	:unit  => "Watt",
	:data => [
		{
			:name => "verbruik laag tarief",
			:type => 'areaspline',
			:data => electra.map { |e| 	time_and_measurement.(e, :electra_import_low) }
		},
		{
			:name => "verbruik normaal tarief",
			:type => 'areaspline',
			:data => electra.map { |e| 	time_and_measurement.(e, :electra_import_normal) }
		},
		{
			:name => "teruglevering laag tarief",
			:type => 'areaspline',
			:data => electra.map { |e| 	time_and_measurement.(e, :electra_export_low) }
		},
		{
			:name => "teruglevering normaal tarief",
			:type => 'areaspline',
			:data => electra.map { |e| 	time_and_measurement.(e, :electra_export_normal) }
		},
	]
}

gas_series = {
	
	:title => "Gas consumption",
	:unit  => "m3",
	:data => [
		{
			:name => "verbruik gas",
			:type => 'areaspline',
			:data => gas.map { |e| time_and_measurement.(e, :gas_usage) }
		}
	]
}

File.open("electra_series.json", 'w') { |file| file.write electra_series.to_json }
File.open("gas_series.json", 'w') { |file| file.write gas_series.to_json }

