Data logging @Home
==

This project has the aim to provide realtime insight in the energie consumption, solar production and the use of other natural resources in the home environment.

> Please note! This software is _not_ ready for prime-time and / or general use. There are no wizards or install scripts that will gently guide you and the software is still in it's _very_ early alpha stage.



Project Structure
====================================

The project comprises of two components; [Kapture](#kapture), for harvesting data and [Kultivate](#kultivate) for providing insights and querying historical data. Measurements are stored in a [Redis](http://redis.io) database and graphs are rendered using [Highcharts](http://www.highcharts.com/) that are fed via a JSON API hosted by [Sinatra](http://www.sinatrarb.com). 


Kapture
----------------

Kapture is build around a naive plugin system where each logger can dump data into the database and publish updates to the UI.

Currently the following devices can be monitored:

* Dutch Smart Meter 'P1' telemetry
	* Electricity & Gas consumption during the day / week 
	* Live power usage  

On the todo list are:

* SMA Solar converter via [SMA Spot](https://code.google.com/p/sma-spot/) 
* OpenTherm gateway

Please see [developing a Kapture plugin](kapture/docs/plugin_development.md) for more technical information.


Kultivate
----------------

Kultivate is a Sinatra web-app that servers the raw measurement data via JSON. Together with some client-side JavaScript transformation graphs are rendered that show the historic data and the actual power consumption.

The [data-range-parser](https://github.com/mobz/date-range-parser) library is used to construct historic data range queries such as 'yesterday', 'last week' and '15->16'.

On the todo list are:

* A lot more graphs and comparison features
* setup wizards
* comparing between users and devices



Available Plugins
====================================

Please check the documentation of each individual plugin to find out more about it's required hardware and configuration settings.

* [P1 Telegram logger](#p1-telegram-logger)

Enabling plugings
-----------

Right now all the plugins are loaded and activated by default. 


Installation
====================================

Both Kapture & Kultivate are written in Ruby and thus require a working Ruby stack. The software has been tested on the 1.9 branch.


Required software
---
* Ruby 1.9 
* Bundler
* Redis

Installing Kapture
---

To install the required gems run the following command 

	bundle install

Start harvesting via

	bundle exed ruby kapture.rb

Installing Kultivate
---

To install the required gems run the following command 

	bundle install

Run

	bundle exed rackup

and surf to

	http://your-machine::9292


P1 Telegram logger
====================================

Monitors a Dutch smart meter for enegery and gas consumption. Every measurements is stored as well as aggregated by day and by week. 
Live power consumption is also provided via redis pub/sub & websockets.

Configuration
------------------------------

*** USB serial device

To find your USB serial TTY execute the following command

	ls /sys/bus/usb-serial/devices/

This gives you an overview of the connected devices (probably 1). Copy this value and execute

	vim kapture/plugins/p1_plugin.rb

Make sure the `/dev/tty<some-name>` equals the device name you've just copied


Required Hardware
------------------------------

* Rapberry PI or simular
* FT232 USB Cable Computer Cable [on ebay](http://www.ebay.com/itm/261101529602)

pinout:

	1 - Black:GND 
	2 - Blue:CTS 
	3 - Red:5V 
	4 - Green:TXD 
	5 - White:RXD 
	6 - Yellow:RTS 

* Smart meter 

connection:

	pin nr / RJ11 function

	2 - request (RTS)
	3 - ground (GND)
	4 - N.C. (N.C.)
	5 - data (RxD)
	
For more informatio see this article on [gejanssen.com](http://gejanssen.com/howto/Slimme-meter-uitlezen/index.html)

FT232 Signal invert
----

Please keep in mind that the Rx signal sent by the Smart Meter is inverted. You can configure this chip using [ft232r_prog](http://rtr.ca/ft232r/) Execute the following command to check the configuration of you FT232 USB chip.

	sudo ./ft232r_prog --dump

inspect the `rxd_inverted` property and make sure it is set to 1. If not, execute

	sudo ./ft232r_prog --invert_rxd

to invert the Rx signal.
