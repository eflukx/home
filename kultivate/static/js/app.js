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

		_.each(result, function(measurement){

			var timestamp = measurement.start_timestamp * 1000;

			var electra_import_low 		= measurement.series[0].electra_import_low;
			var electra_import_normal	= measurement.series[0].electra_import_normal;
			var electra_export_low		= measurement.series[0].electra_export_low;
			var electra_export_normal	= measurement.series[0].electra_export_normal;
			var gas_usage				= measurement.series[2].gas_import;

		 	day_chart_data[0].data.push ([timestamp, electra_import_low] );
			day_chart_data[1].data.push ([timestamp, electra_import_normal] );
			day_chart_data[2].data.push ([timestamp, electra_export_low] );
			day_chart_data[3].data.push ([timestamp, electra_export_normal] );
			day_chart_data[4].data.push ([measurement.series[2].gas_timestamp * 1000, gas_usage] );
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
			var start = _.first(result).start_timestamp * 1000;
			var end   = _.last(result).start_timestamp * 1000;

			$("#start-range").text(Globalize.format( new Date(start), "F" ));
			$("#end-range").text(Globalize.format( new Date(end), "F" ));
		}
	}

	var updateChartWithNewRange = function(){

		var range = window.dateRangeParser.parse($("#date-range").val());

		if(range) {
			var from = new Date(range.start).toUTCString();
			var to   = new Date(range.end).toUTCString();

			$.getJSON('./api/measurement/' + meter_id + '?from='+ from +'&to='+ to, applicationEvents.dailyDataLoaded.dispatch);
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
			$.getJSON('./api/measurement/' + meter_id, applicationEvents.dailyDataLoaded.dispatch );
		}

	}));


});