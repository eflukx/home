require 'redis'
require 'em-websocket'

trap(:INT) { puts; exit }

class LiveUpdater

	def initialize
		@channel = EM::Channel.new
		@redis = Redis.new
	end

	def start
		start_redis_subscriptions_thread
		start_eventmachine_websocket_server_thread
	end	

	private

	def start_redis_subscriptions_thread

		Thread.new do
			@redis.subscribe(:new_measurement) do |on|

				on.message do |channel, message|
					@channel.push message 
				end
			end
		end
	end

	def start_eventmachine_websocket_server_thread

		Thread.new do	

			EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8081) do |ws|
			
				ws.onopen do
					sid = @channel.subscribe do |msg| 
						ws.send msg
					end

					ws.onmessage do |msg|
						@channel.push "<#{sid}>: #{msg}"
					end

					ws.onclose do
						@channel.unsubscribe(sid)
					end
				end
			end
		end
	end

end

