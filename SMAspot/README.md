SMA spot installation instructions
=================

* Download the library from the [SMA spot site](https://code.google.com/p/sma-spot/downloads/list)
* extract the files
* install the needed libraries

	sudo apt-get install --no-install-recommends bluetooth libbluetooth-dev libcurl4-openssl-dev

* to build SMA spot type

	make

* install the results of the build by executing

	sudo chmod +x bin/Release/SMAspot
	sudo cp bin/Release/SMAspot /usr/local/bin/

* create the storage folder

	sudo mkdir -p /var/local/smaspot

* locate the inverters address using `hcitool`

	hcitool scan

* edit the SMAspot.cfg 

	vim SMAspot.cfg

* insert the address found with the previous scan command
* change the plant name to something usefull
* alter the storage path to `/var/local/smaspot`
* visit [this location picker](http://itouchmap.com/latlong.html) and pick the latitude/longitude for your location
* copy the config file to `/etc`

	sudo cp SMAspot.cfg /etc/

* to see if the connection can be established and that everything works as expected, execute

	sudo SMAspot -cfg/etc/SMAspot.cfg -finq -sp0

if things go as expected, there should be a couple of log files containing the measurement data.
