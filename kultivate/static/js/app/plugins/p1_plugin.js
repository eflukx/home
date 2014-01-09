'use strict'

define(function (require) {
    var $ = require('jquery'),
        _ = require('underscore'),
        c = require('highstock'),
        rnd = require('random'),
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

	var updateDailyChart = function(result) {

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

	var updateChartWithNewRange = function(){

	  	var range = window.dateRangeParser.parse($("#"+ options.prefix +"_range").val());

		if(range) {
			var from = new Date(range.start).toUTCString();
			var to   = new Date(range.end).toUTCString();

			alert("sorry, doesn't work yet");

			//$.getJSON('./api/raw/p1/' + meter_id + '?from='+ from +'&to='+ to, applicationEvents.dailyDataLoaded.dispatch);
		}
		else {
			$("#"+ options.prefix +"parse-warning").fadeIn();
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
		prefix : rnd(4)
	}

	return {
		handle:function (result) {

			$(_.template(template, options)).appendTo('.content');

			$("#"+ options.prefix +"_date-range-form").submit(function(e){
				e.preventDefault();
				updateChartWithNewRange();
			});

			updateDateRange(result);
			updateDailyChart(result);
		}
	}

});
