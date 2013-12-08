#!/usr/bin/python

import sys
import serial
import time
import os

serialDevice = "/dev/tty.usbserial-A602N2BW"
outputFolder = "/tmp"

def initSerialPort():

	serialPort = serial.Serial()
	serialPort.baudrate = 9600
	serialPort.bytesize	= serial.SEVENBITS
	serialPort.parity 	= serial.PARITY_EVEN
	serialPort.stopbits = serial.STOPBITS_ONE
	serialPort.xonxoff	= 0
	serialPort.rtscts 	= 0
	serialPort.timeout 	= 20
	serialPort.port 	= serialDevice

	try:
	    serialPort.open()
	except:
	    sys.exit ("Error opening %s."  % serialDevice)      

	return serialPort

def readTelegram(serialPort):
	
	reading_telegram = False
	telegram = []

	line = ''
	while True:
		
	    try:
			line = str(serialPort.readline()).strip()

			if line.startswith('/'):
				reading_telegram = True

			if line == "!" and len(telegram) > 0 & reading_telegram:
				return telegram

			if reading_telegram:
				telegram.append(line)

	    except:
		    sys.exit ("Error reading %s."  % serialDevice)      

def dumpTelegram(telegram):

	timestamp = time.strftime("%Y%m%d-%H%M%S")
	outputFile = os.path.join(outputFolder, timestamp + ".txt")

	print "write to %s" % outputFile

	with open(outputFile, "w") as text_file:
		text_file.write(telegram)


version = "0.1"
print ("chakra - P1 dumper v%s" % version)

serialPort = initSerialPort()

threshold = 0

while True:
	telegram = readTelegram(serialPort)
	threshold = threshold + 1

	print "got data %s" % threshold

	if threshold == 2:
		threshold = 0

		data = "\n".join(telegram)
		dumpTelegram(data)

