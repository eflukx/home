$(function () {
	
    $('#gauge_chart').highcharts({
	
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

});