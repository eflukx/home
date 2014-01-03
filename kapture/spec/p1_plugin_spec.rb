require 'spec_helper'
require 'redis'

require 'lib/logging'
require 'plugins/measurement_plugin'
require 'plugins/p1_plugin'

describe Kapture::Plugins::P1Reader do

	redis = Redis.new

	before(:each) do
		redis.flushdb
		store_new_measurement
	end

	it "should store each items in it's own key space" do

		keys = redis.keys "*"
		keys.length.should eq(15)

		measurement_keys = [:electra_import_low, :electra_import_normal,
							:electra_export_low, :electra_export_normal,
							:gas_usage]

		measurement_keys.each { |k| 
			keys.include?("#{k}.raw/test-device").should eq(true)
			keys.include?("#{k}.byday/test-device").should eq(true)
			keys.include?("#{k}.byweek/test-device").should eq(true)
		}
	end

	it "should store the timestamp value for all expect gas" do
		
		measurement_keys = [:electra_import_low, :electra_import_normal,
							:electra_export_low, :electra_export_normal]

		measurement_keys.each_with_index { |k,i| 
			redis.zrange("#{k}.raw/test-device", 0, 1).first.should eq("{\"timestamp\":10,\"value\":#{i + 1}}")
			redis.hgetall("#{k}.byday/test-device").to_s.should eq("{\"1970/001\"=>\"{\\\"timestamp\\\":10,\\\"value\\\":#{i+1}}\"}")
			redis.hgetall("#{k}.byweek/test-device").to_s.should eq("{\"1970/01\"=>\"{\\\"timestamp\\\":10,\\\"value\\\":#{i+1}}\"}")
		}

	end

	it "should store the gas value for with the gas timestamp" do

		measurement_keys = [:gas_usage]

		measurement_keys.each { |k,i| 
			redis.zrange("#{k}.raw/test-device", 0, 1).first.should eq("{\"timestamp\":2,\"value\":6}")
			redis.hgetall("#{k}.byday/test-device").to_s.should eq("{\"1970/001\"=>\"{\\\"timestamp\\\":2,\\\"value\\\":6}\"}")
			redis.hgetall("#{k}.byweek/test-device").to_s.should eq("{\"1970/01\"=>\"{\\\"timestamp\\\":2,\\\"value\\\":6}\"}")
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