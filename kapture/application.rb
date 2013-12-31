$:.unshift(File.dirname(__FILE__)) unless 
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'lib/plugin'

def load_plugins
	dir = './plugins'
	$LOAD_PATH.unshift(dir)
	Dir[File.join(dir, '*.rb')].each {|file| require File.basename(file) }
end

load_plugins

MeasurementPlugin.repository.each { |plugin| 
	Thread.new do
		plugin.new.go
	end
}
