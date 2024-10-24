#!/bin/bash

function  write_LAN_mac_address()
{
    error_mac1="00:00:00:00:00:00"
    error_mac2="FF:FF:FF:FF:FF:FF"

    O_ETH0=$(sudo ifconfig -a eth0 | awk '/ether/ { print $2 }')
    O_ETH1=$(sudo ifconfig -a eth1 | awk '/ether/ { print $2 }')

    ETH0_TMP=$(/home/srt/eeprom/srgimx8cfg -0 )
    ETH1_TMP=$(/home/srt/eeprom/srgimx8cfg -1 )

    calcheckSum=$(/home/srt/eeprom/srgimx8cfg -p )
	readcheckSum=$(/home/srt/eeprom/srgimx8cfg -k )


    if ( [[ "$ETH0_TMP" == "$error_mac1" ]] || [[ "$ETH0_TMP" == "$error_mac2" ]] ) ; then
			sleep 1
            return
    elif ( [[ "$ETH1_TMP" == "$error_mac1" ]] || [[ "$ETH1_TMP" == "$error_mac2" ]] ) ; then
			sleep 1
            return
	elif [ "$calcheckSum" != "$readcheckSum" ]; then
			sleep 1
            return
    else
			sleep 3
            N_ETH0=$ETH0_TMP
            N_ETH1=$ETH1_TMP
			sudo ifconfig eth0 down
			sudo ifconfig eth1 down

			address=$O_ETH0
			sudo ip link set dev eth0 address ${N_ETH0}

			address=$O_ETH1
			sudo ip link set dev eth1 address ${N_ETH1}

			sleep 1.2
			sudo ifconfig eth0 up
			sudo ifconfig eth1 up
    fi

}


function  write_LAN_LED_setting()
{

    sudo /usr/sbin/mdio-tool w eth0 0x1f 0x0d04
    sudo /usr/sbin/mdio-tool w eth0 0x10 0xC048
    sudo /usr/sbin/mdio-tool w eth0 0x1f 0x0000
    sudo /usr/sbin/mdio-tool w eth1 0x1f 0x0d04
    sudo /usr/sbin/mdio-tool w eth1 0x10 0xC048
    sudo /usr/sbin/mdio-tool w eth1 0x1f 0x0a42
}

function main()
{
    write_LAN_mac_address
    write_LAN_LED_setting
    i2ctransfer -f -y 2 w2@0x51 0x02 0x12
}

main
