#!/bin/bash
# Automatic script for Lolliwiz Kernel

declare -i JOBS
export JOBS=2*$(grep -c processor /proc/cpuinfo)

function build_bootimg {
  ./mkbootimg --kernel arch/arm/boot/zImage --ramdisk ramdisk/initrd_$variant.gz --cmdline "console=null androidboot.hardware=qcom user_debug=23 msm_rtb.filter=0x3b7 dwc3_msm.cpu_to_affin=1" --base 0x00000000 --pagesize 4096 --dt dt.img --ramdisk_offset 0x02600000 --tags_offset 0x02400000 --output boot_$variant.img
  echo SEANDROIDENFORCE >> boot_$variant.img
}

function install_bootimg {
  if [ -e boot_$variant.img ]; then
    if [ "$(adb devices|grep '	recovery')" != "" ]; then
      echo ""
      echo "==========================="
      echo "Installing in recovery mode"
      echo "==========================="
      echo ""
      adb push boot_$variant.img /tmp/boot.img
      adb shell dd if=/tmp/boot.img of=/dev/block/platform/msm_sdcc.1/by-name/boot
    elif [ "$(adb devices|grep '	device')" != "" ]; then
      echo ""
      echo "========================="
      echo "Installing in normal mode"
      echo "========================="
      echo ""
      adb push boot_$variant.img /data/local/tmp/boot.img
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
}

if [ "$1" = "build" ]; then

if [ "$2" != "kt" -a "$2" != "skt" -a "$2" != "lgu" -a "$2" != "all" ]; then
  echo "ERROR: You must specify correct build option : kt / skt / lgu / all"
  exit 1
fi   

echo ""
echo "===================="
echo "Setting up defconfig"
echo "===================="
echo ""

make lw_defconfig

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
echo "==================="
echo "Compressing ramdisk"
echo "==================="
echo ""

rm -f ramdisk/*.gz
cd ramdisk/kt
find . | cpio -o -H newc | gzip > ../initrd_kt.gz
cd ../skt
find . | cpio -o -H newc | gzip > ../initrd_skt.gz
cd ../lgu
find . | cpio -o -H newc | gzip > ../initrd_lgu.gz
cd ../..

if [ "$2" = "all" -o "$2" = "kt" ]; then
  echo ""
  echo "======================"
  echo "Building boot.img : KT"
  echo "======================"
  echo ""
  export variant=kt
  build_bootimg
fi
if [ "$2" = "all" -o "$2" = "skt" ]; then
  echo ""
  echo "======================="
  echo "Building boot.img : SKT"
  echo "======================="
  echo ""
  export variant=skt
  build_bootimg
fi
if [ "$2" = "all" -o "$2" = "lgu" ]; then
  echo ""
  echo "======================="
  echo "Building boot.img : LGU"
  echo "======================="
  echo ""
  export variant=lgu
  build_bootimg
fi

echo ""
echo "==================="
echo "PROCESS COMPLETE!"
echo "OUTPUT : boot_*.img"
echo "==================="
echo ""

elif [ "$1" = "clean" ]; then

make mrproper
if [ -e dt.img ]; then
  echo "  CLEAN   dt.img"
  rm dt.img
fi

elif [ "$1" = "saveconfig" ]; then

if [ -e .config ]; then
  cp .config arch/arm/configs/lw_defconfig
else
  echo "ERROR: .config NOT FOUND"
fi

elif [ "$1" = "install" ]; then

if [ "$2" = "kt" ]; then
  export variant=kt
elif [ "$2" = "skt" ]; then
  export variant=skt
elif [ "$2" = "lgu" ]; then
  export variant=lgu
else
  echo "ERROR: You must specify correct install option : kt / skt / lgu"
  exit 1
fi
install_bootimg

else

echo "Usage: ./lw.sh [build all/kt/sk/lgu / clean / saveconfig / install kt/sk/lgu]"

fi
