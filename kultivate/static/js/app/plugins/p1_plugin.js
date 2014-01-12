'use strict'

define(function (require) {
    var $ = require('jquery'),
        _ = require('underscore'),
        c = require('highstock'),
        rnd = require('random'),
        s = require('sparkline'),
        rangeParser = require('date-range-parser'),
        moment = require('moment'),
        template = require('text!/tmpl/parse_p1.html');

	var createDailyChart = function(result) {

		var day_chart_data = [
			{
				name: 'verbruik laag tarief',
				type: 'areaspline',
				yAxis: 0,
				data: _.find(result.series, function(serie){return serie.measurement_type === "electra_import_low"}).data
			},
			{
				name: 'verbruik normaal tarief',
				type: 'areaspline',
				yAxis: 0,
				data: _.find(result.series, function(serie){return serie.measurement_type === "electra_import_normal"}).data
			},
			{
				name: 'teruglevering laag tarief',
				type: 'areaspline',
				yAxis: 0,
				data: _.find(result.series, function(serie){return serie.measurement_type === "electra_export_low"}).data
			},
			{
				name: 'teruglevering normaal tarief',
				type: 'areaspline',
				yAxis: 0,
				data: _.find(result.series, function(serie){return serie.measurement_type === "electra_export_normal"}).data
			}
		];

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
			series: day_chart_data
		});
	};

	var last_measurements = [	];

	var installLiveListener = function(){
		var websocket = new WebSocket("ws://" + window.location.hostname + ":8081");
		websocket.onmessage = function(evt) {
			var data = JSON.parse(evt.data);
			$("#current_power_consumption").text(data.value + "W");

			last_measurements.push(data.value);

			if(last_measurements.length > 5){
				last_measurements = _.rest(last_measurements,1);
			}

			$("#power_usage").sparkline(last_measurements, {
				type: 'bar',
				barColor: "#57889c",
				height: "26px",
				barWidth: 5,
				barSpacing: 2,
//				stackedBarColor: sparklineStackedColor,
//				negBarColor: sparklineNegBarColor,
				zeroAxis: 'false'
			});

		};
	}

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

			installLiveListener();
			updateDateRange(result);
			createDailyChart(result);
		}
	}

});

