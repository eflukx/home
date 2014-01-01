$:.unshift(File.dirname(__FILE__)) unless 
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Kapture

	require 'logger'
	require 'lib/plugin'
	require 'lib/logging'
	require 'plugins/measurement_plugin'

	include Logging

	#
	# Load the plugins from the 'plugin' folder
	# 
	def self.load_plugins

		Logging::logger.info "loading plugins"

		dir = './plugins'
		$LOAD_PATH.unshift(dir)
		Dir[File.join(dir, '*.rb')].each {|file| require File.basename(file) }
	end

	#
	# Application entry point
	#
	def self.run!

		Logging::logger.info "staring Kapture"

		load_plugins

		Plugins::MeasurementPlugin.repository.each do |plugin| 

			Logging::logger.info "staring #{plugin}"

			Thread.new do
				plugin.new.go
			end
		end

		wait_for_application_exit
	end

	def self.wait_for_application_exit
	
		Logging::logger.info "Kapture has started, now we play the waiting game..."

		running = true
		trap("SIGINT") { running = false }

		while running
		end

		Logging::logger.info "Kapture has won"

	end

end

Thread.abort_on_exception=true 

#Kapture::Logging::logger.level = Logger::DEBUG
Kapture::run!
