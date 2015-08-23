#!/sbin/sh

cd /tmp/lolliwiz

dd if=/dev/block/platform/msm_sdcc.1/by-name/boot of=boot.img
./unpackbootimg -i boot.img
mkdir ramdisk
mv boot.img-ramdisk.gz ramdisk/
cd ramdisk
gunzip -c boot.img-ramdisk.gz|cpio -i
rm boot.img-ramdisk.gz
if ! grep -q f2fs fstab.qcom; then
sed -i 's#/dev/block/platform/msm_sdcc.1/by-name/userdata#/dev/block/platform/msm_sdcc.1/by-name/userdata       /data            f2fs    nosuid,nodev,noatime,background_gc=on                               wait,check,encryptable=footer\n/dev/block/platform/msm_sdcc.1/by-name/userdata#' fstab.qcom
sed -i 's#/dev/block/platform/msm_sdcc.1/by-name/cache#/dev/block/platform/msm_sdcc.1/by-name/cache          /cache           f2fs    nosuid,nodev,noatime,background_gc=on                               wait,check\n/dev/block/platform/msm_sdcc.1/by-name/cache#' fstab.qcom
fi
find . | cpio -H newc -o | gzip -9 > ../boot.img-ramdisk.gz
cd ..
rm -rf ramdisk
echo ./mkbootimg --kernel zImage --ramdisk boot.img-ramdisk.gz --cmdline \"$(cat boot.img-cmdline)\" --base 0x$(cat boot.img-base) --pagesize $(cat boot.img-pagesize) \
               --dt dt.img --ramdisk_offset 0x$(cat boot.img-ramdisk_offset) --tags_offset 0x$(cat boot.img-tags_offset) --output newboot.img > mkbootimg.sh
chmod 777 mkbootimg.sh
./mkbootimg.sh
echo SEANDROIDENFORCE >> newboot.img
dd if=newboot.img of=/dev/block/platform/msm_sdcc.1/by-name/boot

