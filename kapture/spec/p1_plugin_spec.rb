require 'spec_helper'
require 'redis'

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
		keys.length.should eq(15)

		measurement_keys = [:electra_import_low, :electra_import_normal,
							:electra_export_low, :electra_export_normal,
							:gas_usage]

		measurement_keys.each { |k| 
			keys.include?("p1:test-device:#{k}:raw").should eq(true)
			keys.include?("p1:test-device:#{k}:byday").should eq(true)
			keys.include?("p1:test-device:#{k}:byweek").should eq(true)
		}
	end

	it "should store the timestamp value for all expect gas" do
		
		store_new_measurement

		measurement_keys = [:electra_import_low, :electra_import_normal,
							:electra_export_low, :electra_export_normal]

		measurement_keys.each_with_index { |k,i| 
			@redis.zrange("p1:test-device:#{k}:raw", 0, 1).first.should eq "{\"timestamp\":10000,\"value\":#{i + 1}}"
			@redis.hgetall("p1:test-device:#{k}:byday").to_s.should eq("{\"1970/001\"=>\"{\\\"timestamp\\\":10000,\\\"value\\\":#{i+1}}\"}")
			@redis.hgetall("p1:test-device:#{k}:byweek").to_s.should eq("{\"1970/01\"=>\"{\\\"timestamp\\\":10000,\\\"value\\\":#{i+1}}\"}")
		}
	end

	it "should store the gas value for with the gas timestamp" do

		store_new_measurement

		measurement_keys = [:gas_usage]

		measurement_keys.each { |k,i| 
			@redis.zrange("p1:test-device:#{k}:raw", 0, 1).first.should eq("{\"timestamp\":2000,\"value\":6}")
			@redis.hgetall("p1:test-device:#{k}:byday").to_s.should eq("{\"1970/001\"=>\"{\\\"timestamp\\\":2000,\\\"value\\\":6}\"}")
			@redis.hgetall("p1:test-device:#{k}:byweek").to_s.should eq("{\"1970/01\"=>\"{\\\"timestamp\\\":2000,\\\"value\\\":6}\"}")
		}
	end

	def store_new_measurement

		reader = Kapture::Plugins::P1Reader.new

		reader.send :store_new_measurement, {
			:timestamp              => 10,
			:device_id              => "test-device",
			:electra_import_low     => 1,
			:electra_import_normal  => 2,
			:electra_export_low     => 3,
			:electra_export_normal  => 4,
			:current_energy_usage   => 5,
			:gas_usage              => 6,
			:gas_timestamp          => 2
		}
	end

end