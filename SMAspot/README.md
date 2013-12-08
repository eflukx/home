SMAspot installation instructions
=================

These are step-by-step-ish instructions on how to copile, configure & install a daemonize version of the SMAspot Bluetooth reader. 

prerequisites
---

install the required dependencies

	sudo apt-get install --no-install-recommends bluetooth libbluetooth-dev libcurl4-openssl-dev

Next, download the code from the [SMA spot site](https://code.google.com/p/sma-spot/downloads/list) site and extract the files.

To build SMAspot type

	make

Install the output of the build by executing:

	chmod +x bin/Release/SMAspot
	sudo cp bin/Release/SMAspot /usr/local/bin/

Configuration
-----

To locate the address of the SMA converter execute

	hcitool scan

copy the bluethooth address (that the xxxxxxx:yyyyyyyyy one) to your clipboard and create the output folder for the data files;

	sudo mkdir -p /var/local/smaspot

open the `SMAspot.cfg` file (from the source diretory) in an editor and make the following changes 

* insert the address found with the scan command above
* change the plant name to something usefull
* alter the storage path to `/var/local/smaspot`
* visit [this location picker](http://itouchmap.com/latlong.html) and pick the latitude/longitude for your location

Once these changes have been made, the config file can be copied to the `etc` folder.

	sudo cp SMAspot.cfg /etc/

Validation 
----------

To validate if the connection can be established and that everything works as expected, execute

	sudo SMAspot -cfg/etc/SMAspot.cfg -finq -sp0

if things go as expected, there should be a couple of log files in `/var/local/smaspot` containing the measurement data.

Service installation
--------------------

Copy the `SMAspot.conf` file to the service folder

	sudo cp SMAspot/SMAspot.conf /etc/init

start the service by executing

	sudo service SMAspot start

The service will also start on reboot. Please note that [Upstart](http://upstart.ubuntu.com/) is required for these scripts.

