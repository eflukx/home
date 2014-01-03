require 'sinatra/base'

module Kultivate

	class Application < Sinatra::Base
		@@my_app = {}
		def self.new(*) self < Kultivate ? super : Rack::URLMap.new(@@my_app) end
		def self.map(url) @@my_app[url] = self end

		configure do
			set :public_folder, Proc.new { File.join(root, "static") }
		end

		# less style sheet handler
		get '/css/:style.css' do
			content_type 'text/css', :charset => 'utf-8'
			less "less/#{params[:style]}".to_sym
		end

		class ApplicationController < Kultivate::Application
			map '/'
		end

		class ApiController < Kultivate::Application
			map '/api'
		end
	end

end