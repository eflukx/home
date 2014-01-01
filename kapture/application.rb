$:.unshift(File.dirname(__FILE__)) unless 
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'logger'

module Kapture

	require 'lib/plugin'

	def self.logger
		@logger
	end

	def self.logger=(logger)
		@logger = logger
	end

	def self.load_plugins

		logger.info "loading plugins"

		dir = './plugins'
		$LOAD_PATH.unshift(dir)
		Dir[File.join(dir, '*.rb')].each {|file| require File.basename(file) }
	end

	def self.run

		logger.info "staring Kapture"

		load_plugins

		MeasurementPlugin.repository.each do |plugin| 

			logger.info "staring #{plugin}"

			Thread.new do
				plugin.new.go
			end
		end
	end

end

Kapture::logger Logger.new(STDOUT)
Kapture::run
