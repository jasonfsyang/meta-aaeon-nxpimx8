#!/bin/bash -e
#
# Copyright (c) 2013-2015 Robert Nelson <robertcnelson@gmail.com>
# Portions copyright (c) 2014 Charles Steinkuehler <charles@steinkuehler.net>
# Copyright (c) 2020 LYD/AAEON, kunyi <kunyi.chen@gmail.com>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

#This script assumes, these packages are installed, as network may not be setup
#dosfstools initramfs-tools rsync u-boot-tools

if ! id | grep -q root; then
	echo "must be run as root"
	exit
fi

unset root_drive
root_drive=$(LC_ALL=C lsblk -l | grep -v "/media/.*$" | grep "/" | awk '{print $1}')

if [[ "x${root_drive}" = "x" ]] ; then
	echo "Error: script halting, system unrecognized..."
	exit 1
fi

if [[ "x${root_drive}" = "xmmcblk2p"* ]] ; then
	echo "Error: script halting, only support from SD card to eMMC..."
	exit 1
fi

if [[ "x${root_drive}" == "xmmcblk1p"* ]] ; then
	source="/dev/mmcblk1"
	destination="/dev/mmcblk2"
fi

echo "--------------------------------"
echo "rootfs drive: ${root_drive}"
echo "--------------------------------"

flush_cache () {
	sync
	blockdev --flushbufs ${destination}
}

write_failure () {
	echo "writing to [${destination}] failed..."

	[ -e /proc/$CYLON_PID ]  && kill $CYLON_PID > /dev/null 2>&1

	echo "-----------------------------"
	flush_cache
	umount ${destination}p1 || true
	umount ${destination}p2 || true
	exit
}

check_running_system () {
	echo "--------------------------------------------"
	echo "copying: [${source}] -> [${destination}]"
	lsblk
	echo "--------------------------------------------"

	if [ ! -b "${destination}" ] ; then
		echo "Error: [${destination}] does not exist"
		write_failure
	fi
}

update_boot_files () {
	return
	#We need an initrd.img to find the uuid partition
	#update-initramfs -u -k $(uname -r)
}

format_partitions () {
	echo "format partitions"
	flush_cache
	sync

	mkfs.vfat -F 32 -n boot  ${destination}p1
	mkfs.ext4 -qF ${destination}p2 -L rootfs
	flush_cache
	sync
}

partition_drive () {
#	flush_cache

#	NUM_MOUNTS=$(mount | grep -v none | grep "${destination}" | wc -l)

#	for ((i=1;i<=${NUM_MOUNTS};i++))
#	do
#		DRIVE=$(mount | grep -v none | grep "${destination}" | tail -1 | awk '{print $1}')
#		umount ${DRIVE} >/dev/null 2>&1 || umount -l ${DRIVE} >/dev/null 2>&1 || write_failure
#	done

	# erase partition filesystem information

	if mountpoint -q /run/media/boot-mmcblk2p1 ; then 
		echo "It has already mounted : /run/media/boot-mmcblk2p1"
		echo "umount : /run/media/boot-mmcblk2p1" 
		umount /run/media/boot-mmcblk2p1
	fi
	if mountpoint -q /run/media/rootfs-mmcblk2p2 ; then
		echo "It has already mounted : /run/media/rootfs-mmcblk2p2"
		echo "umount : umount /run/media/rootfs-mmcblk2p2"
		umount /run/media/rootfs-mmcblk2p2
	fi

	lsblk

	flush_cache
	echo "erase all data of EMMC"
	dd if=/dev/zero of=${destination} bs=1M count=8 > /dev/null 2>&1  || true
	dd if=/dev/zero of=${destination} bs=1M seek=8 count=1 > /dev/null 2>&1  || true
	dd if=/dev/zero of=${destination} bs=1M seek=136 count=1 > /dev/null 2>&1 || true

	sync
	flush_cache

	# GPT/EFI Partition
	# 8192 sector: 8192*512B, 4MB for bootloader/environments
	# p1: 64MB reserved partition
	# p2: 64MB boot partition, * boot active
	# p3: 2GB, root filesystem,
	# p4: another for user data
	#
	# except the below configuration
	# --------------------------------------------------------------------------------------------
	# Device	 Boot	  Start		     End	  Sectors	Size	Id	Type
	# /dev/mmcblk1p1	   8192		  139263	   131072	 64M	83	Linux
	# /dev/mmcblk1p2 *	 139264		  270335	   131072	 64M	83	Linux
	# /dev/mmcblk1p3	 270336		 3624959	  3354624  1638M	83	Linux
	# /dev/mmcblk1p4	3624960		13692927	 10067968  4916M	83	Linux
	# /dev/mmcblk1p5   13692928     15269854      1576927	770M	83	Linux
	# --------------------------------------------------------------------------------------------
	# >>>--------------- for MBR ----------------------------------
	#LC_ALL=C sfdisk --force "${destination}" <<-__EOF__
	#	8192,	64M, ,
	#	139264, 64M, , *
	#	270336,1638M, ,
	#	3624960,,,-
	#__EOF__
	# <<<----------------------------------------------------------
	# >>>--------------- for GPT/EFI ------------------------------
	LC_ALL=C sgdisk --zap-all --clear "${destination}" > /dev/null 2>&1 || true
	sync
	flush_cache
	dd if=${destination} of=/dev/null bs=1M count=1 > /dev/null 2>&1 || true

	LC_ALL=C sgdisk -n 1:8192:+128MiB -t 1:0c00 -c 1:"boot" -A 1:set:1 -u 1:BC13C2FF-59E6-4262-A352-B275FD6F7172 "${destination}"
	
	sync
	flush_cache
	dd if=${destination} of=/dev/null bs=1M count=1 > /dev/null 2>&1 || true

	LC_ALL=C sgdisk -n 2:: -t 2:8300 -c 2:"rootfs" -u 2:68CBEA7C-EFB6-4AA8-8A78-C19AFBA49203 "${destination}"
	sync
	flush_cache

	
	dd if=${destination} of=/dev/null bs=1M count=1 > /dev/null 2>&1 || true
	sync
	flush_cache
	format_partitions
}



copy_boot () {
	echo "write bootloader into EMMC..."
	dd if=/opt/images/yocto/imx-boot-srg-imx8p-flash_evk of=${destination} bs=1K seek=32 status=progress conv=fsync || write_failure
}

copy_rootfs () {
	local src_boot=${source}p1
	local dst_boot=${destination}p1
	local dst_root=${destination}p2

    sleep 6

	mkdir -p /run/media/boot-mmcblk2p1 || true
	mkdir -p /run/media/rootfs-mmcblk2p2 || true


	mount ${dst_boot} /run/media/boot-mmcblk2p1 -o async,noatime || true
	mount ${dst_root} /run/media/rootfs-mmcblk2p2 -o async,noatime || true

	lsblk

	echo "rsync: / -> /run/media/rootfs-mmcblk2p2/"
	rsync -aAX /* /run/media/rootfs-mmcblk2p2/ --exclude={/dev/*,/proc/*,/sys/*,/tmp/*,/run/*,/mnt/*,/media/*,/lost+found,/test,/LoopTest,/reserved/*,/boot/*} || write_failure
	flush_cache

	#ssh keys will now get regenerated on the next bootup
	#touch run/media/rootfs-mmcblk2p2/etc/ssh/ssh.regenerate
	flush_cache

	# re-enable sshd-regen-keys
	OLDPWD=$PWD
	cd /run/media/rootfs-mmcblk2p2/etc/systemd/system/sysinit.target.wants/
	ln -s /lib/systemd/system/sshd-regen-keys.service sshd-regen-keys.service
	cd $OLDPWD
	unset OLDPWD

	echo "rsync:/run/media/boot-mmcblk1p1/ -> /run/media/boot-mmcblk2p1/"
	rsync -aAIX  /run/media/boot-mmcblk1p1/* /run/media/boot-mmcblk2p1/ --exclude={boot.scr,/lost+found} || write_failure
	flush_cache

	unset boot_uuid
	boot_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value ${dst_boot})
	unset root_uuid
	root_uuid=$(/sbin/blkid -c /dev/null -s UUID -o value ${dst_root})
	if [ "${boot_uuid}" ]; then
		boot_uuid="UUID=${boot_uuid}"
	else
		boot_uuid="${dst_boot}"
	fi
	if [ "${root_uuid}" ]; then
		root_uuid="UUID=${root_uuid}"
	else
		root_uuid="${dst_root}"
	fi
	#generation_fstab

	#dd if=/run/media/rootfs-mmcblk2p2/usr/sbin/boot.scr of=/run/media/boot-mmcblk2p1/boot.scr && sync

	flush_cache
	umount /run/media/boot-mmcblk1p1 || umount -l /run/media/boot-mmcblk1p1 || write_failure
	umount /run/media/boot-mmcblk2p1 || umount -l /run/media/boot-mmcblk2p1 || write_failure
	umount /run/media/rootfs-mmcblk2p2 || umount -l /run/media/rootfs-mmcblk2p2 || write_failure

	# update EEPROM & U-Boot environment variables
	unset ohost
	ohost=$(hostname)


	#https://github.com/beagleboard/meta-beagleboard/blob/master/contrib/bone-flash-tool/emmc.sh#L158-L159
	# force writeback of eMMC buffers
	dd if=${destination} of=/dev/null count=100000


	echo ""
	echo "This script has now completed it's task"
	echo "-----------------------------"
	echo "Note: Actually unpower the board, a reset [sudo reboot] is not enough."
	echo "-----------------------------"

	echo "Shutting Down..."
	sync
	halt
}

check_running_system
CYLON_PID=$!
update_boot_files
partition_drive
copy_boot
copy_rootfs
