require 'rubygems'
require 'rack-flash'
require 'sinatra'

require './config/boot'

LiveUpdater.new.start

run Kultivate::Application
