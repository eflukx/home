P1 data dumper
===============

Simple dump script that writes the serial output from an Iskra MT171 to a time-stamped file.

Required Hardware
----

I'm running this on a Rapberry PI 1ste generation Model B but any general purpose machine with a serial connection should do.

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
	4 -	N.C. (N.C.)
	5 -	data (RxD)

Required Software
----

* python
* pyserial
	> sudo pip install pyserial
* [ft232r_prog](http://rtr.ca/ft232r/)	
* Debian/Ubuntu for the Daemon config

Installation
----

To install this software on your machine run 

	sudo ./install

Configuration
-----

### FT232 Signal invert

Please keep in mind that the Rx signal sent by the Smart Meter is inverted. You can configure this chip using [ft232r_prog](http://rtr.ca/ft232r/) Execute the following command to check the configuration of you FT232 USB chip.

	sudo ./ft232r_prog --dump

inspect the `rxd_inverted` property and make sure it is set to 1. If not, execute

	sudo ./ft232r_prog --invert_rxd

to invert the Rx signal.

### USB serial device

To find your USB serial TTY execute the following command

	ls /sys/bus/usb-serial/devices/

This gives you an overview of the connected devices (probably 1). Copy this value and execute

	sudo vim /usr/local/bin/dumper.py

Make sure the `/dev/tty<some-name>` equals the device name you've just copied

### Output folder

By default all data is written to `/var/local/data-logger`. To alter this, please edit the script 

	sudo vim /usr/local/bin/dumper.py


Starting the logger
-----

to start the monitoring type

	sudo service data-logger start

The service will also start on reboot
