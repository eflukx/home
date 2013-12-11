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
	
	{
	 :timestamp => current[:timestamp],
	 :electra_import_low =>  (current[:telegram].electra_import_low 	 - previous[:telegram].electra_import_low) * to_watts,
	 :electra_import_normal => (current[:telegram].electra_import_normal - previous[:telegram].electra_import_normal) * to_watts,
	 :electra_export_low => (current[:telegram].electra_export_low 		 - previous[:telegram].electra_export_low) * to_watts,
	 :electra_export_normal => (current[:telegram].electra_export_normal - previous[:telegram].electra_export_normal) * to_watts,
	 :gas_usage => current[:telegram].gas_usage							 - previous[:telegram].gas_usage,
	}
end

def as_javascript_timestamp(timestamp)
	timestamp.to_time.to_i * 1000
end

def zero_to_nil(entry)
	entry
	#entry.map{ |e| e > 0 ? e : nil }
end

def time_and_measurement(entry, symbol)
	[ as_javascript_timestamp(entry[:timestamp]) , entry[symbol] ] 
end

file_names = Dir["data-logger/*.txt"]

values = file_names.map(&method(:read_telegram_and_timestamp))#.sort_by{|e| e[:timestamp]}
results = values.drop(1).map.with_index { |value,index| normalize(value, values[index]) }

series = [
	{
		:name => "verbruik laag tarief",
		:type => 'areaspline',
		:data => results.map { |e| 	time_and_measurement(e, :electra_import_low) }.map(&method(:zero_to_nil))
	},
	{
		:name => "verbruik normaal tarief",
		:type => 'areaspline',
		:data => results.map { |e| 	time_and_measurement(e, :electra_import_normal) }.map(&method(:zero_to_nil))
	},
	{
		:name => "teruglevering laag tarief",
		:type => 'areaspline',
		:data => results.map { |e| 	time_and_measurement(e, :electra_export_low) }.map(&method(:zero_to_nil))
	},
	{
		:name => "teruglevering normaal tarief",
		:type => 'areaspline',
		:data => results.map { |e| 	time_and_measurement(e, :electra_export_normal) }.map(&method(:zero_to_nil))
	},
	# {
	#  	:name => "gas verbruik",
	#	:data => results.map { |e| 	select_serie(e, :gas_usage) }.map(&method(:transform_zero_to_null))
	# }
]

puts series.to_json


# puts  { |e| electra_import_low_serie e  }
#puts result.map{|row| "[" + row.join(",") + "],"}
