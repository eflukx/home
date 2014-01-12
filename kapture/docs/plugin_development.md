Writing a Kapture plugin
========================

Each plugin is started in it's own thread and needs to expose a function called 'go!'.

Empty plugin

```ruby
module Kapture

	module Plugins

		class EmptyPlugin < MeasurementPlugin
			require 'eventmachine'
			include Logging

			def initialize
				@redis = Redis.new
			end

			#
			# start watching doing something
			#
			def go!
				EventMachine::run do

					# take some measurment and store this in the database

				end
			end
		end
	end
end
```

Data storage
=============

keys spaces 
-------------

key name must following this naming convention:

	<plugin-name>:<sensor-id>:<measurement-type>:<unit[raw|byday|byweek|]>

examples:

	p1:test-device:electra_import_low:raw
	temp:002:temperature:raw

storage data types
-------------------

### raw measurements

raw measurements are stored in a `sorted set`. 

### aggregated measurements

aggregated measurements are stored in a hash table with fields with the following naming convention:

	<year><interval>

#### aggregated key examples

	p1:electra_import_low:test-device.byday
	
		field => 20141	First day of the year 2014
		field => 201410	Tenth day of the year 2014

	p1:electra_import_low:test-device.byweek

		field => 201350	Week 50 of 2013

> Please note that ISO8601 is followed when it comes to week numbers.

measurment values 
----------

each measurment must be stored as a JSON object with the following structure 

	{
		timestamp: <timestamp as epoch>
		value: <floating point measurement value>
	}

In a raw measument, the Epoch timestamp doubles as the score for sorting


Live data
==============

using redis pub/sub & websockets. Need to come up with a channel naming convention and a way of discovering which channels are available.

Configuration
==============

Nothing here yet
