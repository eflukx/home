#!/usr/bin/env ruby

#
# dummy data generator, generates electricity & gas consumption for 3 months
#

require "redis"
require "json"
require "active_support/core_ext"

class Generator

	attr_reader :redis

	def initialize()
		@redis = Redis.new
	end


	def store_p1_measurement(measurement_data)

		time		= Time.at measurement_data[:timestamp]
		device_id	= measurement_data[:device_id]

		raw_key		= time.to_i
		by_week_key	= time.strftime("%Y/%V")
		by_day_key	= time.strftime("%Y/%j")

		data =->(timestamp_key, measurement_key) {
			{
				:timestamp  => measurement_data[timestamp_key],
				:value      => measurement_data[measurement_key]
			}.to_json
		}

		store_measurement =->(key, data){
			@redis.zadd "#{key}.raw/#{device_id}", raw_key, data
			@redis.hset "#{key}.byday/#{device_id}", by_day_key, data
			@redis.hset "#{key}.byweek/#{device_id}", by_week_key, data
		}

		@redis.pipelined do
			keys = [:electra_import_low, :electra_import_normal,
					:electra_export_low, :electra_export_normal]

			keys.each{|e| store_measurement.(e, data.(:timestamp,e))}
		end
	end

	def generate()

		device_id	= 'test-device'
		interval 	= 15.minutes 
		start_time 	= Time.now - 3.months
		end_time 	= Time.now

		puts "generating"
		cnt = 0

		(start_time.to_i..end_time.to_i).step(interval) do |timestamp|

			print "." if cnt % (interval * 10) == 0
			cnt += interval

			time = Time.at timestamp

			day_time = time.hour > 7 and time.hour < 19

			p1_values = {
				:timestamp 				=> timestamp,
				:device_id				=> device_id,
				:electra_import_low		=> (rand 500 unless day_time) || 0,
				:electra_import_normal 	=> (rand 3000 if day_time) || 0,
				:electra_export_low 	=> (rand 400 unless day_time) || 0,
				:electra_export_normal 	=> (rand 2000 if day_time) || 0
			}

			store_p1_measurement p1_values
		end

		puts "\ndone"

	end
end


Generator.new.generate
