#!/bin/bash
# Automatic script for Lolliwiz Kernel

declare -i JOBS
export JOBS=2*$(grep -c processor /proc/cpuinfo)

if [ "$1" = "build" ]; then

echo ""
echo "===================="
echo "Setting up defconfig"
echo "===================="
echo ""

cp defconfig .config

echo ""
echo "==============="
echo "Building Kernel"
echo "==============="
echo ""

[ -e arch/arm/boot/zImage ] && mv arch/arm/boot/zImage arch/arm/boot/zImage.old
make -j"$JOBS"
if [ -e arch/arm/boot/zImage ]; then
  rm -f arch/arm/boot/zImage.old
else
  [ -e arch/arm/boot/zImage.old ] && mv arch/arm/boot/zImage.old arch/arm/boot/zImage
  echo ""
  echo "==============="
  echo "Build FAILED!!!"
  echo "==============="
  echo ""
  exit 1
fi

echo ""
echo "================="
echo "Building DT Image"
echo "================="
echo ""

tools/dtbTool -o dt.img -s 4096 -p scripts/dtc/ arch/arm/boot/dts/
chmod a+r dt.img

echo ""
echo "================="
echo "Building boot.img"
echo "================="
echo ""

./mkbootimg --kernel arch/arm/boot/zImage --ramdisk boot.img-ramdisk.gz --cmdline "console=null androidboot.hardware=qcom user_debug=23 msm_rtb.filter=0x3b7 dwc3_msm.cpu_to_affin=1" --base 0x00000000 --pagesize 4096 --dt dt.img --ramdisk_offset 0x00f00000 --tags_offset 0x02400000 --output boot.img

echo ""
echo "================="
echo "PROCESS COMPLETE!"
echo "OUTPUT : boot.img"
echo "================="
echo ""

elif [ "$1" = "clean" ]; then

make mrproper
if [ -e dt.img ]; then
  echo "  CLEAN   dt.img"
  rm dt.img
fi

elif [ "$1" = "saveconfig" ]; then

if [ -e .config ]; then
  cp .config defconfig
else
  echo "ERROR: .config NOT FOUND"
fi

elif [ "$1" = "install" ]; then

if [ -e boot.img ]; then
  if [ "$(adb devices|grep '	recovery')" != "" ]; then
    echo ""
    echo "==========================="
    echo "Installing in recovery mode"
    echo "==========================="
    echo ""
    adb push boot.img /tmp/
    adb shell dd if=/tmp/boot.img of=/dev/block/platform/msm_sdcc.1/by-name/boot
  elif [ "$(adb devices|grep '	device')" != "" ]; then
    echo ""
    echo "========================="
    echo "Installing in normal mode"
    echo "========================="
    echo ""
    adb push boot.img /data/local/tmp/
    adb shell su -c dd if=/data/local/tmp/boot.img of=/dev/block/platform/msm_sdcc.1/by-name/boot
    adb reboot
  else
    echo "ERROR: Device not found, make sure your device has USB Debugging option enabled."
    exit 1
  fi
  echo ""
  echo "====================="
  echo "Installation complete"
  echo "====================="
  echo ""
else
  echo "ERROR: No boot.img found, run build first."
fi

else

echo "Usage: ./lw.sh [build/clean/saveconfig/install]"

fi
