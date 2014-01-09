'use strict'

define(function (require) {
    var $ = require('jquery'),
        c = require('highstock'),
        rnd = require('random'),
        template = require('text!/tmpl/generic_widget.html');

	var updateChart = function(result) {

		$("#" + chart_id).highcharts('StockChart',{
			chart: {
				style: {
					fontFamily: '"Open Sans",Arial,Helvetica,Sans-Serif'
				}
			},
			yAxis: [{ 
				gridLineWidth:0,
				title: {
					text: 'unknown data',
				}
			}],
			navigator:{enabled:false},
			scrollbar:{enabled:false},
			rangeSelector:{enabled:false},
			credits: {
				enabled:false
			},			
			series : result.series
		});
	};

	var chart_id = "generic_widget_" + rnd(4);

	return {

		handle:function(result){
			$(_.template(template, { chart_id : chart_id })).appendTo('.content');
			updateChart(result);
		}
	};
});

