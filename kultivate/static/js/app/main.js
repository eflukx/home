'use strict'

define(function (require) {
    var $ = require('jquery'),
        _ = require('underscore');
      	
	$.when( $.getJSON('./api/sensors' ).then( function( sensors ) {

			if(!sensors || $.isArray(sensors) && sensors.length === 0){
				$("#no_data_warning").fadeIn();
			}
			else {

				var generic_plugin = require('app/plugins/generic_plugin');

				_.each(sensors, function(sensor){

					var load_measurement_data = function(handler){
						$.getJSON('./api/raw/' +  sensor.plugin +'/' + sensor.id + '/' + sensor.series.join(":"), handler.handle );
					};

					require(
						["app/plugins/" + sensor.plugin + '_plugin'], 
						function(plugin){
							load_measurement_data(plugin);
						},
						function(error){
							console.warn("Plugin " + sensor.plugin + " failed to load, defaulting to the generic one", error)
							load_measurement_data(generic_plugin);
						});
					
				});
			}
	}));
});