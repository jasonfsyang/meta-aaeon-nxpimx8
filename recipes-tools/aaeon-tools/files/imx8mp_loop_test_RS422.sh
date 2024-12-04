#!/bin/bash

PASS=0
FAIL=-1
loop=1
LAN1=$PASS
LAN2=$PASS
can1_test=$PASS
can2_test=$PASS
cpu_test=$PASS
sd_test=$PASS
usb1_test=$PASS
usb2_test=$PASS
RS232=$PASS
RS485=$PASS
RS422=$PASS
TEST_RESULT=$PASS

RS232=''


# --------------------------------------
# ethernet test
# --------------------------------------
function  ethernet_test()
{

	ETH0_IP=''
	ETH1_IP=''

	
	eval ETH0_IP=$(ip -o -4 addr list eth0  | head -n 1 | awk '{print $4}' | cut -d/ -f1)
	eval ETH1_IP=$(ip -o -4 addr list eth1  | head -n 1 | awk '{print $4}' | cut -d/ -f1)
	
	ping $ETH0_IP -c 4 > eth0.log
	cat eth0.log | grep '0%' > eth0_ping.log
	loss_packet0=`cat eth0_ping.log | cut -d' ' -f6`
	
	ping $ETH1_IP -c 4 > eth1.log
	cat eth1.log | grep '0%' > eth1_ping.log
	loss_packet1=`cat eth1_ping.log | cut -d' ' -f6`
	
	echo "loss_packet0=$loss_packet0"
	echo "loss_packet1=$loss_packet1"
	
	if [ "$loss_packet0" == "0%" ]; then
        LAN1=$PASS
		echo "eth0 [pass]"
    else
        LAN1=$FAIL
		echo "eth0 [fail]"
		ifconfig > eth0_fail$loop".log"
		date >> eth0_fail$loop".log"
    fi
	
	if [ "$loss_packet1" == "0%" ]; then
        LAN2=$PASS
		echo "eth1 [pass]"
    else
        LAN2=$FAIL
		echo "eth1 [fail]"
		ifconfig > eth1_fail$loop".log"
		date >> eth1_fail$loop".log"
    fi
	
	if [  $LAN1 -eq $FAIL ]||[  $LAN2 -eq $FAIL ];then
		TEST_RESULT=$FAIL
	fi
}



function CAN_test()
{
	ifconfig can0 down
	ip link set can0 type can loopback off
	ip link set can0 type can bitrate 1000000 triple-sampling on
        
	ifconfig can1 down
        ip link set can1 type can loopback off
        ip link set can1 type can bitrate 1000000 triple-sampling on
        
	ifconfig can0 up
        ifconfig can1 up
        
	candump can0&
        candump can1&

        cansend can0 111#1122334455667788
        cansend can1 111#8877665544332211
										}											


function cpu_func_test()
{

	cpu_event=0
	/run/media/root-mmcblk1p2/usr/sbin/sysbench cpu --threads=2 run > cpu.log
	cpu_event=` cat cpu.log | grep events: | awk '{print $5}'`

	if [ $cpu_event -gt 300 ]; then
		echo "CPU [pass]"
	else
		echo "CPU [fail]"
		TEST_RESULT=$FAIL
		mv cpu.log  cpu_fail$loop".log"
		date >> cpu_fail$loop".log"
	fi

}

function SD_card_test()
{

	sd_string="This is a SD card test"

	eval sd_path=`lsblk | grep mmcblk1p2 | awk '{print $7}'`

	if [ ${sd_path} ]; then	
		dd if=/dev/zero of=$sd_path"/sdcard_write.bin" bs=1048576 count=1 oflag=direct 2> sdwrite.log
		if [ `du -k $sd_path"/sdcard_write.bin" | awk '{print $1}'` -eq 1024 ]; then
			echo "SDcard Write success `date`"  > sdwrite.log
			echo -e $sd_string > sdtest1.txt
			cp sdtest1.txt sdtest2.txt
			diff sdtest1.txt sdtest2.txt > sd_diff.log
			
			if [ -s sd_diff.log ]; then
				sd_test=$FAIL
				echo -e "sd diff error" > sd_fail$loop".log"
			else
				sd_test=$PASS
			fi
		else
			sd_test=$FAIL
			echo -e "sd write error" > sd_fail$loop".log"
		fi
		
	else
		sd_test=$FAIL
		echo -e "SD card [not plug in]" > sd_fail$loop".log"
	fi

	if [ $sd_test -eq $PASS ]; then
		echo "SD [pass]"
	else
		echo "SD [fail]"
		TEST_RESULT=$FAIL
		lsblk >> sd_fail$loop".log"
		date >> sd_fail$loop".log"
	fi

}

function  usb1_func_test()
{

	tmp1=usb_test.txt

	eval usb_path1=`df | grep sda | awk '{print $6}'`

	if [ ${usb_path1} ]; then
		if [ -e $tmp1 ]; then
			rm -f $tmp1 2>/dev/null
		fi
		
		if [ -e usbwrite.log ]; then
			rm -f usbwrite.log 2>/dev/null
		fi

		dd if=/dev/zero of=$usb_path1"/usb_write.bin" bs=1048576 count=50 oflag=direct 2>> usbwrite.log
		if [ `du -k $usb_path1"/usb_write.bin" | awk '{print $1}'` -eq 51200 ]; then
			echo "USB1 /dev/sda Write success `date`"  >> usbwrite.log
			echo -e "This is a USB1 test" >> usb_test.txt
			
			tmp2=$usb_path1"/usb_test.txt"
			
			cp $tmp1 $tmp2
			

			if [ -e usb_diff.log ]; then
				rm -f usb_diff.log 2>/dev/null
			fi
			
			if [ -e $tmp2 ]; then
				diff $tmp1 $tmp2 > usb_diff.log
				if [ -s usb_diff.log ]; then
					usb1_test=$FAIL
					echo -e "USB1 diff error" >> usb1cpu$loop".log"
				else
					usb1_test=$PASS
				fi
			else
				usb1_test=$FAIL
				echo -e "USB1 copy file error" >> usb1_fail$loop".log"
			fi
		else
			echo "USB1 /dev/sda write error `date`" >> usb1_fail$loop".log"
			usb1_test=$FAIL
		fi
	else
		usb1_test=$FAIL
		echo "It can't recognize USB device" >> usb1_fail$loop".log"
	fi


	if [ $usb1_test -eq $PASS ]; then
		echo "USB1 [pass]"
	else
		echo "USB1 [fail]"
		TEST_RESULT=$FAIL
		lsblk >> usb1_fail$loop".log"
		lsusb >> usb1_fail$loop".log"
		date >> usb1_fail$loop".log"

	fi


}

function  usb2_func_test()
{

	tmp1=usb_test.txt

	eval usb_path2=`df | grep sdb | awk '{print $6}'`

	if [ ${usb_path2} ]; then
		if [ -e $tmp1 ]; then
			rm -f $tmp1 2>/dev/null
		fi
		
		if [ -e usbwrite.log ]; then
			rm -f usbwrite.log 2>/dev/null
		fi

		dd if=/dev/zero of=$usb_path2"/usb_write.bin" bs=1048576 count=50 oflag=direct 2>> usbwrite.log
		if [ `du -k $usb_path2"/usb_write.bin" | awk '{print $1}'` -eq 51200 ]; then
			echo "USB2 /dev/sda Write success `date`"  >> usbwrite.log
			echo -e "This is a USB2 test" >> usb_test.txt
			
			tmp2=$usb_path2"/usb_test.txt"
			
			cp $tmp1 $tmp2
			

			if [ -e usb_diff.log ]; then
				rm -f usb_diff.log 2>/dev/null
			fi
			
			if [ -e $tmp2 ]; then
				diff $tmp1 $tmp2 > usb_diff.log
				if [ -s usb_diff.log ]; then
					usb2_test=$FAIL
					echo -e "USB2 diff error" >> usb2_fail$loop".log"
				else
					usb2_test=$PASS
				fi
			else
				usb2_test=$FAIL
				echo -e "USB2 copy file error" >> usb2_fail$loop".log"
			fi
		else
			echo "USB2 /dev/sda write error `date`" >> usb2_fail$loop".log"
			usb2_test=$FAIL
		fi
	else
		usb2_test=$FAIL
		echo "It can't recognize USB device" >> usb2_fail$loop".log"
	fi


	if [ $usb2_test -eq $PASS ]; then
		echo "USB2 [pass]"
	else
		echo "USB2 [fail]"
		TEST_RESULT=$FAIL
		lsblk >> usb2_fail$loop".log"
		lsusb >> usb2_fail$loop".log"
		date >> usb2_fail$loop".log"

	fi

}

function RS232_test()
{
	
	gpioset 2 21=0
	gpioset 2 22=1
	gpioset 2 23=0
	gpioset 0 12=1

	stty -F /dev/ttymxc0 115200 raw            #CONFIGURE SERIAL PORT
	stty -F /dev/ttymxc2 115200 raw            #CONFIGURE SERIAL PORT
	
	if [ -f ttyDumpMU0.dat ]; then
		rm ttyDumpMU0.dat
	fi
	if [ -f ttyDumpMU1.dat ]; then
		rm ttyDumpMU1.dat
	fi
	

	exec 3</dev/ttymxc2                        #REDIRECT SERIAL OUTPUT TO FD 3
		cat <&3 > ttyDumpMU1.dat &            #REDIRECT SERIAL OUTPUT TO FILE
		PID=$!                                #SAVE PID TO KILL CAT
			echo "send-to-MU0" > /dev/ttymxc0  #SEND COMMAND STRING TO SERIAL PORT
			sleep 0.2s                        #WAIT FOR RESPONSE
		kill $PID                             #KILL CAT PROCESS
		wait $PID 2>/dev/null                 #SUPRESS "Terminated" output
	exec 3<&-                                 #FREE FD 3
	

	exec 3</dev/ttymxc0
	cat <&3 > ttyDumpMU0.dat &
		PID=$!
			echo "send-to-MU1" > /dev/ttymxc2
			sleep 0.2s
		kill $PID
		wait $PID 2>/dev/null
	exec 3<&-
	
	
	if [ `cat ttyDumpMU1.dat | grep -c send-to-MU0` -ne 1 ]; then
		echo "Exp-B RS232 fail - ttyMU0 -> ttyMU1"
	fi
	
	if [ `cat ttyDumpMU0.dat | grep -c send-to-MU1` -ne 1 ]; then
		echo "Exp-B RS232 fail - ttyMU1 -> ttyMU0"
	fi
	
	if [ `cat ttyDumpMU1.dat | grep -c send-to-MU0` -eq 1 ]; then
		if [ `cat ttyDumpMU0.dat | grep -c send-to-MU1` -eq 1 ]; then
			echo "RS232 [pass]"
			RS232=$PASS
		else
			echo "RS232 [fail]"
			RS232=$FAIL
			cp ttyDumpMU0.dat 232_p0_fail$loop".log"
			cp ttyDumpMU1.dat 232_p1_fail$loop".log"
			date >> 232_p0_fail$loop".log"
			date >> 232_p1_fail$loop".log"
		fi
	else
		echo "RS232 [fail]"
		RS232=$FAIL
		cp ttyDumpMU0.dat 232_p0_fail$loop".log"
		cp ttyDumpMU1.dat 232_p1_fail$loop".log"
		date >> 232_p0_fail$loop".log"
		date >> 232_p1_fail$loop".log"
	fi
	if [ $RS232 -eq $FAIL ]; then
		TEST_RESULT=$FAIL
	fi
	
}

function RS485_test()
{

	gpioset 2 21=1
	gpioset 2 22=0
	gpioset 2 23=1
	gpioset 0 12=0

	stty -F /dev/ttymxc0 115200 raw            #CONFIGURE SERIAL PORT
	stty -F /dev/ttymxc2 115200 raw            #CONFIGURE SERIAL PORT
	
	if [ -f ttyDumpMU0.dat ]; then
		rm ttyDumpMU0.dat
	fi
	if [ -f ttyDumpMU1.dat ]; then
		rm ttyDumpMU1.dat
	fi
	

	exec 3</dev/ttymxc2                        #REDIRECT SERIAL OUTPUT TO FD 3
		cat <&3 > ttyDumpMU1.dat &            #REDIRECT SERIAL OUTPUT TO FILE
		PID=$!                                #SAVE PID TO KILL CAT
			echo "send-to-MU0" > /dev/ttymxc0  #SEND COMMAND STRING TO SERIAL PORT
			sleep 0.2s                        #WAIT FOR RESPONSE
		kill $PID                             #KILL CAT PROCESS
		wait $PID 2>/dev/null                 #SUPRESS "Terminated" output
	exec 3<&-                                 #FREE FD 3
	

	exec 3</dev/ttymxc0
	cat <&3 > ttyDumpMU0.dat &
		PID=$!
			echo "send-to-MU1" > /dev/ttymxc2
			sleep 0.2s
		kill $PID
		wait $PID 2>/dev/null
	exec 3<&-
	
	
	if [ `cat ttyDumpMU1.dat | grep -c send-to-MU0` -ne 1 ]; then
		echo "Exp-B RS485 fail - ttyMU0 -> ttyMU1"
	fi
	
	if [ `cat ttyDumpMU0.dat | grep -c send-to-MU1` -ne 1 ]; then
		echo "Exp-B RS485 fail - ttyMU1 -> ttyMU0"
	fi
	
	if [ `cat ttyDumpMU1.dat | grep -c send-to-MU0` -eq 1 ]; then
		if [ `cat ttyDumpMU0.dat | grep -c send-to-MU1` -eq 1 ]; then
			echo "RS485 [pass]"
			RS485=$PASS
		else
			echo "RS485 [fail]"
			RS485=$FAIL
			cp ttyDumpMU0.dat 485_p0_fail$loop".log"
			cp ttyDumpMU1.dat 485_p1_fail$loop".log"
			date >> 485_p0_fail$loop".log"
			date >> 485_p1_fail$loop".log"
		fi
	else
		echo "RS485 [fail]"
		RS485=$FAIL
		cp ttyDumpMU0.dat 485_p0_fail$loop".log"
		cp ttyDumpMU1.dat 485_p1_fail$loop".log"
		date >> 485_p0_fail$loop".log"
		date >> 485_p1_fail$loop".log"
	fi
	if [ $RS485 -eq $FAIL ]; then
		TEST_RESULT=$FAIL
	fi
	
}


function RS422_test()
{


	gpioset 2 21=0
	gpioset 2 22=0
	gpioset 2 23=0
	gpioset 0 12=0


	stty -F /dev/ttymxc0 115200 raw            #CONFIGURE SERIAL PORT
	stty -F /dev/ttymxc2 115200 raw            #CONFIGURE SERIAL PORT
	
	if [ -f ttyDumpMU0.dat ]; then
		rm ttyDumpMU0.dat
	fi
	if [ -f ttyDumpMU1.dat ]; then
		rm ttyDumpMU1.dat
	fi
	

	exec 3</dev/ttymxc2                        #REDIRECT SERIAL OUTPUT TO FD 3
		cat <&3 > ttyDumpMU1.dat &            #REDIRECT SERIAL OUTPUT TO FILE
		PID=$!                                #SAVE PID TO KILL CAT
			echo "send-to-MU0" > /dev/ttymxc0  #SEND COMMAND STRING TO SERIAL PORT
			sleep 0.2s                        #WAIT FOR RESPONSE
		kill $PID                             #KILL CAT PROCESS
		wait $PID 2>/dev/null                 #SUPRESS "Terminated" output
	exec 3<&-                                 #FREE FD 3
	

	exec 3</dev/ttymxc0
	cat <&3 > ttyDumpMU0.dat &
		PID=$!
			echo "send-to-MU1" > /dev/ttymxc2
			sleep 0.2s
		kill $PID
		wait $PID 2>/dev/null
	exec 3<&-
	
	
	if [ `cat ttyDumpMU1.dat | grep -c send-to-MU0` -ne 1 ]; then
		echo "Exp-B RS422 fail - ttyMU0 -> ttyMU1"
	fi
	
	if [ `cat ttyDumpMU0.dat | grep -c send-to-MU1` -ne 1 ]; then
		echo "Exp-B RS422 fail - ttyMU1 -> ttyMU0"
	fi
	
	if [ `cat ttyDumpMU1.dat | grep -c send-to-MU0` -eq 1 ]; then
		if [ `cat ttyDumpMU0.dat | grep -c send-to-MU1` -eq 1 ]; then
			echo "RS422 [pass]"
			RS422=$PASS
		else
			echo "RS422 [fail]"
			RS422=$FAIL
			cp ttyDumpMU0.dat 422_p0_fail$loop".log"
			cp ttyDumpMU1.dat 422_p1_fail$loop".log"
			date >> 422_p0_fail$loop".log"
			date >> 422_p1_fail$loop".log"
		fi
	else
		echo "RS422 [fail]"
		RS422=$FAIL
		cp ttyDumpMU0.dat 422_p0_fail$loop".log"
		cp ttyDumpMU1.dat 422_p1_fail$loop".log"
		date >> 422_p0_fail$loop".log"
		date >> 422_p1_fail$loop".log"
	fi
	if [ $RS422 -eq $FAIL ]; then
		TEST_RESULT=$FAIL
	fi
	
}

function LED_OFF()
{
	for i in {1..7}
	do
	    m0cli -c 0 -i $i -v 0
	done
}
function loop_test()
{
	PASS_COUNT=0
	FAIL_COUNT=0

	ifconfig can0 down
	ip link set can0 type can loopback off
	ip link set can0 type can bitrate 1000000 triple-sampling on
	
	ifconfig can1 down
	ip link set can1 type can loopback off
	ip link set can1 type can bitrate 1000000 triple-sampling on
	
	ifconfig can0 up
	ifconfig can1 up
	ifconfig can0 txqueuelen 1000000
	ifconfig can1 txqueuelen 1000000
	
	if [ -e LoopTest.txt ]; then
		rm -f LoopTest.txt  2>/dev/null
	fi
         
	while :
	do

	    LAN1=$PASS
	    LAN2=$PASS
	    can1_test=$PASS
	    can2_test=$PASS
	    cpu_test=$PASS
	    sd_test=$PASS
	    usb1_test=$PASS
	    usb2_test=$PASS
	    RS232=$PASS
		RS485=$PASS
	    RS422=$PASS
	    TEST_RESULT=$PASS	
            
	    LED_OFF
            led_num=${loop:0-1}

            if [ $led_num -eq 0 ]; then
                LED_OFF
            elif [ $led_num -eq 8 ]; then 
                m0cli -c 0 -i 1 -v 1
                m0cli -c 0 -i 7 -v 1
            elif [ $led_num -eq 9 ]; then 
                m0cli -c 0 -i 1 -v 1
                m0cli -c 0 -i 2 -v 1
                m0cli -c 0 -i 7 -v 1
            else
                m0cli -c 0 -i $led_num -v 1
            fi

	    echo "LOOP: $loop"
            CAN_test
	    usb1_func_test
	    usb2_func_test
	    cpu_func_test
	    SD_card_test
	    RS422_test
	    ethernet_test

	    echo -e "\n\n"
	    if [ $TEST_RESULT -eq $PASS ]; then
		PASS_COUNT=$(($PASS_COUNT+1))
		echo "LOOP$loop: PASS" >> LoopTest.txt
	    else
		FAIL_COUNT=$(($FAIL_COUNT+1))
		echo "LOOP$loop: FAIL"  >> LoopTest.txt
		dmesg > kernel_$loop".log"
	    fi	

	    echo -e "Total test count:" $loop "\n"
	    echo -e "Pass count:" $PASS_COUNT "\n"
	    echo -e "Fail count" $FAIL_COUNT
	    echo -e "\n\n"
	    ((loop=$loop+1)) 
		
	done

}

loop_test

