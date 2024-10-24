#!/bin/bash
while true
do
	#i2cset -y 2 0x23 0x00 0x56
	#sleep 5
	#i2cdetect -y 2
	#sleep 2
	m0cli -s
	sleep 25
done
