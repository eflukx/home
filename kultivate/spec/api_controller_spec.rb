ENV['RACK_ENV'] = 'test'

require 'rspec'
require 'rack/test'
require 'redis'
require 'json'

require 'spec_helper'
require 'config/boot'

describe 'Api Controller' do
	include Rack::Test::Methods

	def app
		Sinatra::Application
	end

	it "should list the available meters" do
		get '/css/test.css'
		expect(last_response).to be_ok

		#result = JSON.parse last_response.body

		#expect result.length.to eq 1
		#expect result.first.to eq('test-device')
	end

	it "says hello" do
		get '/api/measurements'
		expect(last_response).to be_ok
		expect(last_response.body).to eq('Hello World')
	end
end