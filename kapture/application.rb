$:.unshift(File.dirname(__FILE__)) unless 
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Kapture

	require 'lib/plugin'
	require 'plugins/measurement_plugin'
	require 'logger'

	def self.logger
		@logger ||= Logger.new(STDOUT)
	end

	def self.logger=(logger)
		@logger = logger
	end

	#
	# Load the plugins from the 'plugin' folder
	# 
	def self.load_plugins

		logger.info "loading plugins"

		dir = './plugins'
		$LOAD_PATH.unshift(dir)
		Dir[File.join(dir, '*.rb')].each {|file| require File.basename(file) }
	end

	#
	# Application entry point
	#
	def self.run!

		logger.info "staring Kapture"

		load_plugins

		Plugins::MeasurementPlugin.repository.each do |plugin| 

			logger.info "staring #{plugin}"

			Thread.new do
				plugin.new.go
			end
		end

		wait_for_application_exit
	end

	def self.wait_for_application_exit
	
		logger.info "Kapture has started, now we play the waiting game..."

		running = true
		trap("SIGINT") { running = false }

		while running
		end

		logger.info "Kapture has won"

	end

end


Kapture::run!
