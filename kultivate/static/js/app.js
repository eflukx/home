$(function() {

	'use strict'

	$.ajaxSetup({cache: false});

	var updateDailyChart = function(result) {

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

		var data_map = {
			"electra_import_low"	:0,
			"electra_import_normal" :1,
			"electra_export_low" 	:2,
			"electra_export_normal" :3
		};

		_.each(result, function(serie){
			day_chart_data[data_map[serie.type]].data = serie.data;
		});

		$("#daily_chart").highcharts('StockChart',{
			chart: {
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
			scrollbar:{enabled:false},
			rangeSelector:{enabled:false},
			yAxis: [{ 
				gridLineWidth:0,
				labels: {
					formatter: function() {
						return this.value +'°W';
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
			series : day_chart_data
		});
	};

	var updateDateRange = function(result){

		if(result === undefined || $.isArray(result) && result.length == 0){
			$("#end-range").text("no data");
		}
		else {
			var series = _.first(result);

			var start = _.first(series.data)[0];
			var end   = _.last(series.data)[1];

			$("#start-range").text(Globalize.format( new Date(start), "F" ));
			$("#end-range").text(Globalize.format( new Date(end), "F" ));
		}
	}

	var updateChartWithNewRange = function(){

		var range = window.dateRangeParser.parse($("#date-range").val());

		if(range) {
			var from = new Date(range.start).toUTCString();
			var to   = new Date(range.end).toUTCString();

			$.getJSON('./api/measurements/' + meter_id + '?from='+ from +'&to='+ to, applicationEvents.dailyDataLoaded.dispatch);
		}
		else {
			$("#parse-warning").fadeIn();
		}
	}

	$("#date-range-form").submit(function(e){
		e.preventDefault();
		updateChartWithNewRange();
	});

	var meter_id;

	var applicationEvents = {
	  dailyDataLoaded : new signals.Signal()
	};

	applicationEvents.dailyDataLoaded.add(updateDailyChart);
	applicationEvents.dailyDataLoaded.add(updateDateRange);

	$.when( $.getJSON('./api/meters' ).then( function( data ) {

		meter_id = _.last(data);

		if(!meter_id){
			$("#no-data-warning").show();
		}
		else {
			$.getJSON('./api/measurements/' + meter_id, applicationEvents.dailyDataLoaded.dispatch );
		}

	}));

});