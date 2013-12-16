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

def normalize(current, previous)

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
	 #:gas_usage => current[:telegram].gas_usage							 - previous[:telegram].gas_usage,
	}
end

def as_javascript_timestamp(timestamp)
	timestamp.to_time.to_i * 1000
end


def time_and_measurement(entry, symbol)
	[ as_javascript_timestamp(entry[:timestamp]) , entry[symbol] ] 
end

file_names = Dir["data-logger/*.txt"]

values = file_names.map(&method(:read_telegram_and_timestamp)).select{ |e| e[:telegram].valid? }.group_by{ |e| e[:timestamp].to_i / (3 * 60) }
values = values.keys.map{ |e| values[e].last }

results = values.drop(1).map.with_index { |value,index| normalize(value, values[index]) }

series = [
	{
		:name => "verbruik laag tarief",
		:type => 'areaspline',
		:data => results.map { |e| 	time_and_measurement(e, :electra_import_low) }
	},
	{
		:name => "verbruik normaal tarief",
		:type => 'areaspline',
		:data => results.map { |e| 	time_and_measurement(e, :electra_import_normal) }
	},
	{
		:name => "teruglevering laag tarief",
		:type => 'areaspline',
		:data => results.map { |e| 	time_and_measurement(e, :electra_export_low) }
	},
	{
		:name => "teruglevering normaal tarief",
		:type => 'areaspline',
		:data => results.map { |e| 	time_and_measurement(e, :electra_export_normal) }
	},
	# {
	#  	:name => "gas verbruik",
	#	:data => results.map { |e| 	select_serie(e, :gas_usage) }
	# }
]

puts series.to_json


# puts  { |e| electra_import_low_serie e  }
#puts result.map{|row| "[" + row.join(",") + "],"}
