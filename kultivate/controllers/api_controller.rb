require 'sinatra/base'
require 'redis'
require 'date'
require 'json'
require 'active_support/core_ext'

module Kultivate

	class Application

		class ApiController

			redis = Redis.new

			get '/sensors' do
				content_type :json

				keys = redis.keys "*:raw"

				JSON.generate keys.map { |key|
				parts = key.split(':')
					{
						:plugin => parts[0],
						:id 	=> parts[1],
						:series	=> keys.select{|key| key.starts_with? "#{parts[0]}:#{parts[1]}"}.map{|m| m.split(":")[2]}
					}
				 }.uniq
			end

			get '/raw/:plugin/:sensor_id/?:measurement_series?' do |plugin, sensor_id, measurement_series|

				content_type :json

				from = Time.parse(params[:from] ||= Date.today.to_s)
				to 	 = Time.parse(params[:to] ||= Date.tomorrow.to_s)

				# if non of the measurement series where specified, we load the all
				if measurement_series == nil
					measurement_series = redis.keys("#{plugin}:#{sensor_id}:*:raw").map{|m| m.split(":")[2]}.join(":")
				end

				keys = measurement_series.split(':')

				redis_data = redis.pipelined do
					keys.each do |key|
						redis.zrangebyscore "#{plugin}:#{sensor_id}:#{key}:raw", from.to_i, to.to_i	
					end
				end

				from_json = Proc.new { |str| JSON.parse(str).values }

				{
					:plugin		=>	plugin,
					:sensor_id	=>	sensor_id,
					:start_time => 	from,
					:end_time	=> 	to,
					:series		=> 	keys.map.with_index { |key, index|
										{
											:measurement_type => key,
											:data => redis_data[index].map(&from_json)
										}
									}
				}.to_json

			end

			# get %r{/measurement/(.*)/by(week|day)} do |meter_id, type|

			# 	content_type :json

			# 	format = "%V" if type == 'week'
			# 	format = "%j" if type == 'day'

			# 	start = 10.weeks.ago if type == 'week'
			# 	start = 30.days.ago if type == 'day'

			# 	from = Time.parse(params[:from] ||= start.to_date.to_s )
			# 	to 	 = Time.parse(params[:to] ||= Date.today.to_s)

			# 	fields = (from.to_i..to.to_i).step(1.day).map { |timestamp| 	
			# 		Time.at(timestamp).strftime("%Y/#{format}")
			# 	}.uniq

			# #	puts "measurement.by#{type}/#{meter_id}", fields

			# 	result = redis.hmget "measurement.by#{type}/#{meter_id}", fields

			# 	JSON.generate Kultivatr::Electricity::day_usage result.reject(&:blank?).map{ |e| Kultivatr::Telegram.from_json e } 
			# end
			
		end
	end
end