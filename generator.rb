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
				:timestamp  => measurement_data[timestamp_key] * 1000,
				:value      => measurement_data[measurement_key]
			}.to_json
		}

		store_measurement =->(key, data){
			@redis.zadd "p1:#{device_id}:#{key}:raw", raw_key, data
			@redis.hset "p1:#{device_id}:#{key}:byday", by_day_key, data
			@redis.hset "p1:#{device_id}:#{key}:byweek", by_week_key, data
		}

		@redis.pipelined do
			keys = [:electra_import_low, :electra_import_normal,
					:electra_export_low, :electra_export_normal]

			keys.each{|e| store_measurement.(e, data.(:timestamp,e))}
		end
	end

	def generate_p1_data()

		puts "generating p1 sensor data"
		cnt = 0

		device_id	= 'test-device'
		interval 	= 15.minutes 
		start_time 	= Time.now - 3.months
		end_time 	= Time.now

		(start_time.to_i..end_time.to_i).step(interval) do |timestamp|

			print "." if cnt % (interval * 10) == 0
			cnt += interval

			time = Time.at timestamp

			day_time = time.hour > 7 and time.hour < 19

			map = {
				:timestamp 				=> timestamp,
				:device_id				=> device_id,
				:electra_import_low		=> (rand 500 unless day_time) || 0,
				:electra_import_normal 	=> (rand 3000 if day_time) || 0,
				:electra_export_low 	=> (rand 10 unless day_time) || 0,
				:electra_export_normal 	=> (rand 2000 if day_time) || 0
			}

			store_p1_measurement map
		end

		puts "\ndone"

	end

	def store_temperature_measurement(measurement_data)

		time		= Time.at measurement_data[:timestamp]
		device_id	= measurement_data[:device_id]

		raw_key		= time.to_i
		by_week_key	= time.strftime("%Y/%V")
		by_day_key	= time.strftime("%Y/%j")

		data =->(timestamp_key, measurement_key) {
			{
				:timestamp  => measurement_data[timestamp_key] * 1000,
				:value      => measurement_data[measurement_key]
			}.to_json
		}

		store_measurement =->(key, data){
			@redis.zadd "p1:#{device_id}:#{key}:raw", raw_key, data
			@redis.hset "p1:#{device_id}:#{key}:byday", by_day_key, data
			@redis.hset "p1:#{device_id}:#{key}:byweek", by_week_key, data
		}

		@redis.pipelined do
			keys = [:electra_import_low, :electra_import_normal,
					:electra_export_low, :electra_export_normal]

			keys.each{|e| store_measurement.(e, data.(:timestamp,e))}
		end
	end

	def generate_temperature_data

		puts "generating temperature sensor data"
		cnt = 0

		device_id	= '1'
		interval 	= 5.minutes 
		start_time 	= Time.now - 1.day
		end_time 	= Time.now

		(start_time.to_i..end_time.to_i).step(interval) do |timestamp|

			print "." if cnt % (interval * 10) == 0
			cnt += interval

			time = Time.at timestamp

			day_time = time.hour > 7 and time.hour < 19

			temperature = ((18 if day_time) || 10 ) + rand(5)

			map = {
				:timestamp 	=> timestamp,
				:value		=> temperature
			}

			@redis.zadd "temperature:#{device_id}:temperature:raw", timestamp, map.to_json
		end

		puts "\ndone"
	end

	def generate()

		generate_p1_data
		generate_temperature_data

	end
end


Generator.new.generate
