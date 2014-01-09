'use strict'

define(function (require) {
    var $ = require('jquery'),
        _ = require('underscore'),
        c = require('highstock'),
        rnd = require('random'),
        rangeParser = require('date-range-parser'),
        moment = require('moment'),
        template = require('text!/tmpl/parse_p1.html');

	var day_chart_data = [
		{
			name: 'verbruik laag tarief',
			type: 'areaspline',
			yAxis: 0,
			data: []
		},
		{
			name: 'verbruik normaal tarief',
			type: 'areaspline',
			yAxis: 0,
			data: []
		},
		{
			name: 'teruglevering laag tarief',
			type: 'areaspline',
			yAxis: 0,
			data: []
		},
		{
			name: 'teruglevering normaal tarief',
			type: 'areaspline',
			yAxis: 0,
			data: []
		},
		{
			name: 'gas verbruik',
			type: 'column',
			yAxis: 1,
			data: []
		}
	];

	var createDailyChart = function(result) {

 		var chart = new Highcharts.StockChart({
			chart: {
				renderTo : options.prefix + "_daily_chart",
				style: {
					fontFamily: '"Open Sans",Arial,Helvetica,Sans-Serif'
				}
			},
			colors:[
					'#6baed6',
					'#4292c6',
					'#2171b5',
					'#08519c',
					'#08306b'
			],
			navigator:{enabled:false},
			scrollbar:{enabled:false},
			rangeSelector:{enabled:false},
			yAxis: [{ 
				gridLineWidth:0,
				labels: {
					formatter: function() {
						return this.value +'W';
					},
					style: {
						color: '#89A54E'
					}
				},
				title: {
					text: 'Electricity usage',
					style: {
						color: '#89A54E'
					}
				}
				}, {
				gridLineColor: 'rgba(0,0,0,0.05)',
				opposite: true,
				title: {
					text: 'Gas usage',
					style: {
						color: '#4572A7'
					}
				},
			}],
			plotOptions:{
				series:{
					marker:{
						enabled:false
					}
				}
			},				
			credits: {
				enabled:false
			},			
		});

		var data_map = {
			"electra_import_low"	:0,
			"electra_import_normal" :1,
			"electra_export_low" 	:2,
			"electra_export_normal" :3
		};

		_.each(result.series, function(serie){
			day_chart_data[data_map[serie.measurement_type]].data = serie.data 
			chart.addSeries ( day_chart_data[data_map[serie.measurement_type]] );
		});
	};

	var createGaugeChart = function(){

		$('#'+ options.prefix +'_gauge_chart').highcharts({
		
		    chart: {
		        type: 'gauge',
		        plotBackgroundColor: null,
		        plotBackgroundImage: null,
		        plotBorderWidth: 0,
		        plotShadow: false
		    },

			credits: {
				enabled:false
			},	
		    
		    title: {
		        text: 'actual power'
		    },
		    
		    pane: {
		        startAngle: -150,
		        endAngle: 150,
		        background: [{
		            backgroundColor: {
		                linearGradient: { x1: 0, y1: 0, x2: 0, y2: 1 },
		                stops: [
		                    [0, '#FFF'],
		                    [1, '#333']
		                ]
		            },
		            borderWidth: 0,
		            outerRadius: '109%'
		        }, {
		            backgroundColor: {
		                linearGradient: { x1: 0, y1: 0, x2: 0, y2: 1 },
		                stops: [
		                    [0, '#333'],
		                    [1, '#FFF']
		                ]
		            },
		            borderWidth: 1,
		            outerRadius: '107%'
		        }, {
		            // default background
		        }, {
		            backgroundColor: '#DDD',
		            borderWidth: 0,
		            outerRadius: '105%',
		            innerRadius: '103%'
		        }]
		    },
		       
		    // the value axis
		    yAxis: {
		        min: 0,
		        max: 6000,
		        
		        minorTickInterval: 'auto',
		        minorTickWidth: 1,
		        minorTickLength: 10,
		        minorTickPosition: 'inside',
		        minorTickColor: '#666',
		
		        tickPixelInterval: 30,
		        tickWidth: 2,
		        tickPosition: 'inside',
		        tickLength: 10,
		        tickColor: '#666',
		        labels: {
		            step: 3,
		            rotation: 'auto',
					style: {
						fontSize: '8px'
					}
		        },
		        plotBands: [{
		            from: 0,
		            to: 2000,
		            color: '#55BF3B' // green
		        }, {
		            from: 2000,
		            to: 4000,
		            color: '#DDDF0D' // yellow
		        }, {
		            from: 4000,
		            to: 6000,
		            color: '#DF5353' // red
		        }]        
		    },
		
		    series: [{
		        name: 'W',
		        data: [0],
		        tooltip: {
		            valueSuffix: ' W'
		        },
				dataLabels: {
					enabled: true,
				}
		    }]
		}, 
		// Add some life
		function (chart) {
			if (!chart.renderer.forExport) {

				var websocket = new WebSocket("ws://" + window.location.hostname + ":8081");
				websocket.onmessage = function(evt) {
					var data = JSON.parse(evt.data);
					var point = chart.series[0].points[0];
					point.update(parseInt(data.current_power_usage));
				};
			}
		});
	};


	var updateChartWithNewRange = function(){

	  	var range = rangeParser.parse($("#"+ options.prefix +"_date_range").val());

		if(range && range.start && range.end) {
			
			var from = new Date(range.start).toUTCString();
			var to   = new Date(range.end).toUTCString();

			$.getJSON('./api/raw/' + options.plugin + '/' + options.sensor_id + '?from='+ from +'&to='+ to, function(result){
				createDailyChart(result);
				updateDateRange(result);
			});
		}
		else {
			$("#"+ options.prefix +"_parse_warning").fadeIn().delay(2000).fadeOut();
		}
	}

	var updateDateRange = function(result){

		if(result === undefined || $.isArray(result) && result.length == 0){
			$("#"+ options.prefix +"_start-range").text("");
			$("#"+ options.prefix +"_end-range").text("no data");
		}
		else {
			var start = moment(result.start_time);
			var end   = moment(result.end_time);

			$("#"+ options.prefix +"_start-range").text(start.format("dddd, MMMM Do YYYY, H:mm:ss"));
			$("#"+ options.prefix +"_end-range").text(end.format("dddd, MMMM Do YYYY, H:mm:ss"));
		}
	}

	var options = {
		prefix : rnd(4),
		sensor_id : null,
		plugin: null
	};

	return {
		handle:function (result) {

			options.plugin = result.plugin;
			options.sensor_id = result.sensor_id;

			$(_.template(template, options)).appendTo('.content');

			$("#"+ options.prefix +"_date-range-form").submit(function(e){
				e.preventDefault();
				updateChartWithNewRange();
			});

			createGaugeChart();
			updateDateRange(result);
			createDailyChart(result);
		}
	}

});

