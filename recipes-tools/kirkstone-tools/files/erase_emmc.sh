#!/bin/bash

sudo dd if=/dev/zero of=/dev/mmcblk2 bs=1k seek=32 count=1 > /dev/null 2>&1  || true


