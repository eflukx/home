require "sinatra/base"
require "sass"

module Kultivate

	class Application < Sinatra::Base
		@@my_app = {}
		def self.new(*) self < Kultivate::Application ? super : Rack::URLMap.new(@@my_app) end
		def self.map(url) @@my_app[url] = self end

		enable :sessions
		use Rack::Flash

		configure do
			set :public_folder, Proc.new { File.join(root, "static") }
		end

		# less style sheet handler
		get '/css/:style.css' do
			content_type 'text/css', :charset => 'utf-8'
			scss "sass/#{params[:style]}".to_sym
		end

		class ApplicationController < Kultivate::Application
			map '/'
		end

		class ApiController < Kultivate::Application
			map '/api'
		end
	end

end