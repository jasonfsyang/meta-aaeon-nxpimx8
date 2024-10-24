#!/bin/bash


# gpio5 for USB1_PWR_EN
# gpio6 for USB2_PWR_EN
# gpio114 for MC1_Reset_EN
# gpio115 for MC1_Reset_EN

# all pin to low
#gpioset 0 5=0
#gpioset 0 6=0
gpioset 3 18=0
gpioset 3 19=0
sleep 0.8
# for MC1_Reset_EN and MC2_Reset_EN reset
gpioset 3 18=1
gpioset 3 19=1
