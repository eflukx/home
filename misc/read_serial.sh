DEVICE=/dev/ttyUSB2

stty -F $DEVICE 9600 cs7 -cstopb evenp -icanon min 1 time 1
while true; do
        read LINE < $DEVICE
        echo $LINE
done
