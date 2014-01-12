#!/usr/bin/env ruby

$:.unshift(File.dirname(__FILE__)) unless 
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

module Kapture

	require 'eventmachine'
	require 'active_support/core_ext/hash'

	require 'logger'
	require 'kapture/version'
	require 'kapture/lib/plugin'
	require 'kapture/lib/logging'
	require 'kapture/plugins/measurement_plugin'

	include Logging

	#
	# Load the plugins from the 'plugin' folder
	# 
	def self.load_plugins

		Logging::logger.info "loading plugins"

		dir = File.dirname(__FILE__) + '/../lib/kapture/plugins'

		Logging::logger.info "plugin folder #{dir}"

		$LOAD_PATH.unshift(dir)
		plugins = (Dir[File.join(dir, '*.rb')])
		plugins = plugins.select{ |e| !e.end_with? "measurement_plugin.rb" } 
		Logging::logger.info "found #{plugins.length} plugins"

		plugins.each {|file| require File.basename(file) }
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
				plugin.new.go!
			end
		end

		wait_for_application_exit
	end

	def self.wait_for_application_exit
	
		Logging::logger.info "Kapture has started, now we play the waiting game..."

		trap("SIGINT") { EventMachine::stop_event_loop }

		EventMachine::run{

		}

		Logging::logger.info "Kapture has won"

	end

end

Thread.abort_on_exception=true 

require 'trollop'

opts = Trollop::options do
  version "Kapture #{Kapture::VERSION} (c) 2014 Ernst Naezer"
  banner <<-EOS
Kapture hosts a set of measurement plugins that harvest data with the aim to provide realtime insight
in the energie consumption, solar production and the use of other natural resources in the home environment.

Usage:
       kapture [options] 
where [options] are:
EOS

  opt :debug, "Set logging to Debug level"
end

Kapture::Logging::logger.level = opts[:debug] ? Logger::DEBUG : Logger::INFO  
Kapture::Logging::logger.debug "hurray debug mode!"

Kapture::run!
