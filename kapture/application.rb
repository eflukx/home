$:.unshift(File.dirname(__FILE__)) unless 
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Kapture

	require 'lib/plugin'

	def self.logger
		@logger
	end

	def self.logger=(logger)
		@logger = logger
	end

	def self.load_plugins
		dir = './plugins'
		$LOAD_PATH.unshift(dir)
		Dir[File.join(dir, '*.rb')].each {|file| require File.basename(file) }
	end

	def self.run

		load_plugins

		MeasurementPlugin.repository.each do |plugin| 
			Thread.new do
				plugin.new.go
			end
		end
	end

end

Kapture::logger Logger.new(STDOUT)
Kapture::run

