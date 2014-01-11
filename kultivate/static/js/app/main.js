'use strict'

define(function (require) {
    var $ = require('jquery'),
        _ = require('underscore');

	require("sparkline")

	$.ajaxSetup({ cache: false });
   
   	$(".power_usage").each(function(){

        var $this = $(this);
		var sparklineType = $this.data('sparkline-type') || 'bar';
	   	
		// BAR CHART
		if (sparklineType === 'bar') {
			var barColor = $this.data('sparkline-bar-color') || $this.css('color') || '#0000f0',
				sparklineHeight = $this.data('sparkline-height') || '26px',
				sparklineBarWidth = $this.data('sparkline-barwidth') || 5,
				sparklineBarSpacing = $this.data('sparkline-barspacing') || 2,
				sparklineNegBarColor = $this.data('sparkline-negbar-color') || '#A90329',
				sparklineStackedColor = $this.data('sparkline-barstacked-color') || ["#A90329","#0099c6", "#98AA56", "#da532c", "#4490B1", "#6E9461", "#990099", "#B4CAD3"];

			$this.sparkline('html', {
				type: 'bar',
				barColor: barColor,
				height: sparklineHeight,
				barWidth: sparklineBarWidth,
				barSpacing: sparklineBarSpacing,
				stackedBarColor: sparklineStackedColor,
				negBarColor: sparklineNegBarColor,
				zeroAxis: 'false'
			});
		}

	     //LINE CHART
	    if (sparklineType === 'line') {

			var sparklineHeight = $this.data('sparkline-height') || '20px',
				sparklineWidth = $this.data('sparkline-width') || '90px',
				thisLineColor = $this.data('sparkline-line-color') || $this.css('color') || '#0000f0',
				thisLineWidth = $this.data('sparkline-line-width') || 1,
				thisFill = $this.data('fill-color') || '#c0d0f0',
				thisSpotColor = $this.data('sparkline-spot-color') || '#f08000',
				thisMinSpotColor = $this.data('sparkline-minspot-color') || '#ed1c24',
				thisMaxSpotColor = $this.data('sparkline-maxspot-color') || '#f08000',
				thishighlightSpotColor = $this.data('sparkline-highlightspot-color') || '#50f050',
				thisHighlightLineColor = $this.data('sparkline-highlightline-color') || 'f02020',
				thisSpotRadius = $this.data('sparkline-spotradius') || 1.5,
				thisChartMinYRange = $this.data('sparkline-min-y') || 'undefined', 
				thisChartMaxYRange = $this.data('sparkline-max-y') || 'undefined', 
				thisChartMinXRange = $this.data('sparkline-min-x') || 'undefined', 
				thisChartMaxXRange = $this.data('sparkline-max-x') || 'undefined', 
				thisMinNormValue = $this.data('min-val') || 'undefined', 
				thisMaxNormValue = $this.data('max-val') || 'undefined',
				thisNormColor = $this.data('norm-color') || '#c0c0c0', 
				thisDrawNormalOnTop = $this.data('draw-normal') || false;

			$this.sparkline('html', {
				type: 'line',
				width: sparklineWidth,
				height: sparklineHeight,
				lineWidth: thisLineWidth,
				lineColor: thisLineColor,
				fillColor: thisFill,
				spotColor: thisSpotColor,
				minSpotColor: thisMinSpotColor,
				maxSpotColor: thisMaxSpotColor,
				highlightSpotColor: thishighlightSpotColor,
				highlightLineColor: thisHighlightLineColor,
				spotRadius: thisSpotRadius,
				chartRangeMin: thisChartMinYRange,
				chartRangeMax: thisChartMaxYRange,
				chartRangeMinX: thisChartMinXRange,
				chartRangeMaxX: thisChartMaxXRange,
				normalRangeMin: thisMinNormValue,
				normalRangeMax: thisMaxNormValue,
				normalRangeColor: thisNormColor,
				drawNormalOnTop: thisDrawNormalOnTop
			});
		}
	});

	// $('.power_usage').sparkline('html', {
	// 	type:'bar'
	// });

	$.when( $.getJSON('./api/sensors' ).then( function( sensors ) {

			if(!sensors || $.isArray(sensors) && sensors.length === 0){
				$("#no_data_warning").fadeIn();
			}
			else {

				var generic_plugin = require('app/plugins/generic_plugin');

				_.each(_.sortBy(sensors, function(sensor){return sensor.plugin;}).reverse(), function(sensor){

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