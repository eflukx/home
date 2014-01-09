require 'sinatra/base'
require 'redis'
require 'date'
require 'json'
require 'active_support/core_ext'

module Kultivate

	class Application

		class ApiController

			redis = Redis.new

			get '/meters' do
				content_type :json

				JSON.generate redis.keys("*:raw").map { |key| key.split(':')[1] }.uniq
			end

			get '/measurements/:sensor_id' do |sensor_id|

				content_type :json

				from = Time.parse(params[:from] ||= Date.today.to_s)
				to 	 = Time.parse(params[:to] ||= Date.tomorrow.to_s)

				keys = [:electra_import_low, :electra_import_normal,
						:electra_export_low, :electra_export_normal]

				redis_data = redis.pipelined do
					keys.each do |key|
						redis.zrangebyscore "p1:#{sensor_id}:#{key}:raw", from.to_i, to.to_i	
					end
				end

				result = keys.map.with_index do |key, index|
					{
						:type => key,
						:data => redis_data[index].map { |e| 
								r = JSON.parse(e, :symbolize_names => true)
								[ r[:timestamp], r[:value] ]
						}
					}
				end

				{
					:start_time => from,
					:end_time	=> to,
					:series		=> result
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