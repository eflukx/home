#!/usr/bin/python

#
# Dutch Smart Meter telegram dump script.
# 
# This script reads a telegram from an Iskra Smart Meter
# and writes it to a time-stamped file for future processing.
#

import sys
import serial
import time
import os

serialDevice = "/dev/ttyUSB0"
outputFolder = "/var/local/data-logger"
threshold    = 35 # capture evey 35-th message (+/- 5 minutes @ 6 messages per minute)  

def initSerialPort():

  serialPort = serial.Serial()
  serialPort.baudrate = 9600
  serialPort.bytesize = serial.SEVENBITS
  serialPort.parity   = serial.PARITY_EVEN
  serialPort.stopbits = serial.STOPBITS_ONE
  serialPort.xonxoff  = 0
  serialPort.rtscts   = 0
  serialPort.timeout  = 20
  serialPort.port     = serialDevice

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

  with open(outputFile, "w") as text_file:
    text_file.write(telegram)


version = "0.1"
print ("chakra - P1 dumper v%s" % version)

serialPort = initSerialPort()

counter = 0

while True:
  telegram = readTelegram(serialPort)
  counter = counter + 1

  if counter == threshold:
    counter = 0
    data = "\n".join(telegram)
    dumpTelegram(data)

