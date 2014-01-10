require 'spec_helper'
require 'redis'
require "active_support/core_ext"

require 'kapture/lib/logging'
require 'kapture/plugins/measurement_plugin'
require 'kapture/plugins/p1_plugin'

describe Kapture::Plugins::P1Reader do

	attr_reader :redis

	before(:each) do
		@redis = Redis.new
		@redis.flushdb
	end

	it "should store each items in it's own key space" do

		store_new_measurement

		keys = @redis.keys "*"
		keys.length.should eq 4

		measurement_keys = [:electra_import_low, :electra_import_normal,
							:electra_export_low, :electra_export_normal]

		measurement_keys.each { |k| 
			keys.include?("p1:test-device:#{k}:raw").should eq(true)
			#keys.include?("p1:test-device:#{k}:byday").should eq(true)
			#keys.include?("p1:test-device:#{k}:byweek").should eq(true)
		}
	end

	it "should store the timestamp value for all expect gas" do
		
		store_new_measurement

		measurement_keys = [:electra_import_low, :electra_import_normal,
							:electra_export_low, :electra_export_normal]

		measurement_keys.each_with_index { |k,i| 
			@redis.zrange("p1:test-device:#{k}:raw", 0, 1).first.should eq "{\"timestamp\":10000,\"value\":#{i + 1}}"
			#@redis.hgetall("p1:test-device:#{k}:byday").to_s.should eq("{\"1970/001\"=>\"{\\\"timestamp\\\":10000,\\\"value\\\":#{i+1}}\"}")
			#@redis.hgetall("p1:test-device:#{k}:byweek").to_s.should eq("{\"1970/01\"=>\"{\\\"timestamp\\\":10000,\\\"value\\\":#{i+1}}\"}")
		}
	end

	# it "should store the gas value for with the gas timestamp" do

	# 	store_new_measurement

	# 	measurement_keys = [:gas_usage]

	# 	measurement_keys.each { |k,i| 
	# 		@redis.zrange("p1:test-device:#{k}:raw", 0, 1).first.should eq("{\"timestamp\":2000,\"value\":6}")
	# 		@redis.hgetall("p1:test-device:#{k}:byday").to_s.should eq("{\"1970/001\"=>\"{\\\"timestamp\\\":2000,\\\"value\\\":6}\"}")
	# 		@redis.hgetall("p1:test-device:#{k}:byweek").to_s.should eq("{\"1970/01\"=>\"{\\\"timestamp\\\":2000,\\\"value\\\":6}\"}")
	# 	}
	# end

	def store_new_measurement

		reader = Kapture::Plugins::P1Reader.new

		reader.send(:save_measurement_to_redis, {
			:timestamp              => 10,
			:device_id              => "test-device",
			:electra_import_low     => 1,
			:electra_import_normal  => 2,
			:electra_export_low     => 3,
			:electra_export_normal  => 4,
			:current_energy_usage   => 5
		})
	end

	it "should calculate the delta between two measurements in Watt" do

		reader = Kapture::Plugins::P1Reader.new 

		current = {
          :timestamp             => 1.hour,
          :device_id             => 'test-device',
          :electra_import_low    => 1,
          :electra_import_normal => 2,
          :electra_export_low    => 3,
          :electra_export_normal => 4			
		}

		previous = {
          :timestamp             => 0,
          :device_id             => 'test-device',
          :electra_import_low    => 0,
          :electra_import_normal => 0,
          :electra_export_low    => 0,
          :electra_export_normal => 0			
		}

		result = reader.send :calculate_delta, previous, current

		result[:timestamp].should eq 1.hour
		result[:device_id].should eq 'test-device'
		result[:electra_import_low].should eq 1000
		result[:electra_import_normal].should eq 2000
		result[:electra_export_low].should eq 3000
		result[:electra_export_normal].should eq 4000
	end

	it "should parse p1 telegrams and store the delta" do
		reader = Kapture::Plugins::P1Reader.new

		dir = File.dirname(__FILE__) + '/p1_telegrams/*.txt'

		Dir.glob(dir) do |fname|
			reader.send :handle_new_telegram, File.read(fname)

			# we have to sleep for a while, otherwise redis won't store the 
			# measurement because the timer hasn't advanced enough for it to be
			# a unique entry in the set  
			sleep 1
		end

		size = @redis.zcard "p1:XMX5XMXABCE100085870:electra_import_normal:raw"
		size.should eq 3

		raw = @redis.zrange "p1:XMX5XMXABCE100085870:electra_import_normal:raw", 0, 100
		
		m = raw.map { |e| JSON.parse e }

		m[0]["value"].should eq 244799.99999994106
		m[1]["value"].should eq 720000.0000001637
		m[2]["value"].should eq 2797200.0000001574
	end

end