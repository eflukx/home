#!/usr/bin/env python

#
# Dutch Smart Meter telegram dump script.
# 
# This script reads a telegram from an Iskra Smart Meter
# and writes it to a time-stamped file for future processing.
#

import logging
import sys
import serial
import time
import os
import signal

SERIAL_DEVICE = "/dev/ttyUSB0"
OUTPUT_FOLDER = "/var/local/data-logger"
THRESHOLD     = 6 # capture every n-th message (10 seconds)  
LOG_FILE      = '/var/log/data-logger.log'
LOG_LEVEL     = logging.ERROR

logger        = None
serial_port   = None

def init_logger():
  FORMAT = '%(asctime)-15s %(levelname)-6s %(message)s'
  DATE_FORMAT = '%b %d %H:%M:%S'

  logger = logging.getLogger('data-logger')
  logger.setLevel(LOG_LEVEL)
  formatter = logging.Formatter(fmt=FORMAT, datefmt=DATE_FORMAT)

  handler = logging.FileHandler(filename = LOG_FILE)
  handler.setFormatter(formatter)
  logger.addHandler(handler)

  return logger

def signal_handler(signal, frame):
  logger.info('exit!')
  serial_port.close()
  sys.exit(0)

def init_serial_port():
  serial_port = serial.Serial()
  serial_port.baudrate 	= 9600
  serial_port.bytesize	= serial.SEVENBITS
  serial_port.parity	= serial.PARITY_EVEN
  serial_port.stopbits	= serial.STOPBITS_ONE
  serial_port.xonxoff 	= 0
  serial_port.rtscts 	= 0
  serial_port.timeout 	= None
  serial_port.port 	= SERIAL_DEVICE

  try:
    serial_port.open()
  except:
    logger.execption("Error opening serial device: {0}.".format(SERIAL_DEVICE))      
    sys.exit(1)

  return serial_port

def read_telegram(serial_port):
  logger.debug("waiting for telegram")

  reading_telegram = False
  telegram = []

  line = ''

  serial_port.flushInput()
  serial_port.write('/?!\r\n')
  
  while True:    
    try:
      buffer = ''

      while True:
        buffer += serial_port.read(serial_port.inWaiting())

        if '\n' in buffer:
          #line = buffer.strip(['\0','\n','\r'])
          line = buffer
          line = line.replace('\0', '')
          line = line.replace('\r', '')
          line = line.replace('\n', '')
	  break

      logger.debug("read line: {0} ; len({1})".format(line, len(line)))

      if line.startswith('/'):
        logger.debug("found start token")
        telegram = []
        reading_telegram = True

      if reading_telegram:
        telegram.append(line)
      
      if line == '!' and len(telegram) > 1 and reading_telegram:
        return '\n'.join(telegram)

    except:
      logger.exception("Error reading serial device {0}.".format(SERIAL_DEVICE))
      sys.exit(1)

def dump_telegram(telegram):

  timestamp = time.strftime("%Y%m%d-%H%M%S")
  output_file = os.path.join(OUTPUT_FOLDER, timestamp + ".txt")

  logger.info("dumping telegram to {0}".format(output_file))

  try:
     with open(output_file, "w") as text_file:
    	text_file.write(telegram)
  except:
    logger.exception("Failed writing file")
    sys.exit(1)

# -------------------------------------------
# main entry point
# -------------------------------------------

signal.signal(signal.SIGINT, signal_handler)

version = "0.1"
print ("chakra - P1 dumper v{0}".format(version))

logger = init_logger()

serial_port = init_serial_port()
counter = 0
first_message = True

logger.info("starting")

while True:
  telegram = read_telegram(serial_port)
  counter = counter + 1

  logger.info("got a telegram. Counter is at {0}".format(counter))

  if counter >= THRESHOLD or first_message == True:
    counter = 0
    first_message = False
    dump_telegram(telegram)

