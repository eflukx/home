module Kapture

  module Plugins

    require 'redis'
    require 'kapture/lib/plugin'

    class MeasurementPlugin
      include Plugin

      #
      # start a measurement plugin
      # this operation will typically block im a while true loop
      #
      def go!
        raise NotImplementedError.new('OH NOES!')
      end

    end
  end
end