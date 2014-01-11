'use strict'

//$.ajaxSetup({cache: false});

requirejs.config({
	baseUrl: "js/lib",
	paths: {
		"app": "../app",
		"jquery": "//ajax.googleapis.com/ajax/libs/jquery/2.0.3/jquery.min",
		"highstock": "highcharts/highcharts-more",
		"highstock.base": "highcharts/highstock",
		"underscore": "//cdnjs.cloudflare.com/ajax/libs/underscore.js/1.5.2/underscore-min",
		"moment": "moment.min",
		"sparkline":"jquery.sparkline.min"
	},
	shim: {
		"highstock": {
			deps: [ "jquery", "highstock.base"],
			exports: "Highcharts"
		},
		"underscore":{
			exports: "_"
		},
		"date-range-parser":{
			exports: "dateRangeParser"
		}
	}
});

requirejs(["app/main"]);
