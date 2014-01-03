require 'rubygems'
require 'bundler'

Bundler.require
require './config/boot'

LiveUpdater.new.start

run Kultivate::Application
