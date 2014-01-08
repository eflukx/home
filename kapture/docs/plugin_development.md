Writing a Kapture plugin
========================

General setup
-------

Each plugin is started in it's own thread and needs to expose a function called 'go!'.

Empty plugin

	module Kapture

		module Plugins

			class EmptyPlugin < MeasurementPlugin

				include Logging

				attr_reader :redis

				def initialize
					@redis = Redis.new
				end

				#
				# start watching doing something
				#
				def go!
					while(true)

						# take some measurment and store this in the database

					end
				end
			end
		end
	end


Data storage
---------

Something about key spacing naming convention

key name:
	<plugin-name>:<measurement-type>:<meter-id>.[raw|day|week|month|]

key value:

	{
		timestamp:
		value:
	}

raw measument is a sorted set with the timestamp as the score

aggregated data is a hash key

Live data
--------

using redis pub/sub & websockets. Need to come up with a channel naming convention and a way of discovering which channels are available.

Configuration
----------

Nothing here yet
