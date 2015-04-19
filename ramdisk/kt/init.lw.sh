#!/system/bin/sh

# Enable Sweep2Sleep
echo 1 > /sys/sweep2sleep/sweep2sleep

# Disable securestorage support
mount -o rw,remount /system
sed -i 's/ro.securestorage.support=true/ro.securestorage.support=false/' /system/build.prop

