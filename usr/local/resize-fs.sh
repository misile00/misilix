#!/bin/sh
# This script will attempt to resize the partition and filesystem in order to fill the drive and do a few other minor adjustments to the system
 # Credits to rpi-distro and dietpi https://github.com/RPi-Distro/raspi-config/, https://github.com/MichaIng/DietPi/

Reboot_to_load_Partition_table()
{
	systemctl enable resize-fs.service
	echo '[ INFO ] Rebooting to load the new partition table'
	reboot
	exit 0
}

# Disable this service
systemctl disable resize-fs.service

# Get device and partition numbers/names
 # Root Partition
PART_DEV=`findmnt / -o source -n | cut -f1 -d"["`

# Remove '/dev/' from the name 
PART_NAME=`echo $PART_DEV | cut -d "/" -f 3`

# Set just the name of the device, usually mmcblk0
DEV_NAME=`echo /sys/block/*/${PART_NAME} | cut -d "/" -f 4`

# Add /dev/ to device name
DEV="/dev/${DEV_NAME}"

# Get Number of device as single digit integer
PART_NUM=`cat /sys/block/${DEV_NAME}/${PART_NAME}/partition`

# Get size of SDCard (final sector)
SECTOR_SIZE=`cat /sys/block/${DEV_NAME}/size`

# Set the ending sector that the partition should be resized too
END_SECTOR=`expr $SECTOR_SIZE - 1`

# Resize the partition
# parted command disabled for now. Using sfdisk instead
#parted -m $DEV u s resizepart $PART_NUM yes $END_SECTOR
echo ", +" | sfdisk --no-reread -N $PART_NUM $DEV

# Inform kernel about changed partition table, be failsafe by using two different methods and reboot if any fails
partprobe "$DEV" || Reboot_to_load_Partition_table
partx -u "$DEV" || Reboot_to_load_Partition_table

# Detect root filesystem type
ROOT_FSTYPE=$(findmnt -Ufnro FSTYPE -M /)

# Maximise root filesystem if type is supported
case $ROOT_FSTYPE in
	'ext'[234]) resize2fs "$PART_DEV" || reboot;; # Reboot if resizing fails
	'f2fs')
		mount -o remount,ro /
		resize.f2fs "$PART_DEV"
		mount -o remount,rw /
	;;
	'btrfs') btrfs filesystem resize max /;;
	*)
		echo "[FAILED] Unsupported root filesystem type ($ROOT_FSTYPE). Aborting..."
		exit 1
	;;
esac

# Change fstab to boot partition UUID
genfstab -U / > /etc/fstab

exit 0
