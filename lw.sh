#!/bin/bash
# Automatic script for Lolliwiz Kernel

BOLD=$(tput bold)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)
RESET=$(tput sgr0)

declare -i JOBS
export JOBS=2*$(grep -c processor /proc/cpuinfo)

function echocyan {
  echo $BOLD$CYAN▶ $1$RESET
}

function echored {
  echo $BOLD$RED▶ $1$RESET
}

function build_bootimg {
  ./mkbootimg --kernel arch/arm/boot/zImage --ramdisk ramdisk/initrd_$variant.gz --cmdline "console=null androidboot.hardware=qcom user_debug=31 msm_rtb.filter=0x37 dwc3_msm.cpu_to_affin=1" --base 0x00000000 --pagesize 4096 --dt dt.img --ramdisk_offset 0x02200000 --tags_offset 0x02000000 --output boot_$variant.img
  echo SEANDROIDENFORCE >> boot_$variant.img
}

function install_bootimg {
  if [ -e boot_$variant.img ]; then
    if [ "$(adb devices|grep '	recovery')" != "" ]; then
      echo ""
      echocyan "Installing in recovery mode"
      adb push boot_$variant.img /tmp/boot.img
      adb shell dd if=/tmp/boot.img of=/dev/block/platform/msm_sdcc.1/by-name/boot
    elif [ "$(adb devices|grep '	device')" != "" ]; then
      echo ""
      echocyan "Installing in normal mode"
      adb push boot_$variant.img /data/local/tmp/boot.img
      adb shell su -c dd if=/data/local/tmp/boot.img of=/dev/block/platform/msm_sdcc.1/by-name/boot
      adb reboot
    else
      echored "ERROR: Device not found, make sure your device has USB Debugging option enabled."
      exit 1
    fi
    echo ""
    echocyan "Installation complete"
  else
    echored "ERROR: No boot.img found, run build first."
  fi
}

if [ "$1" = "build" ]; then

if [ "$2" != "kt" -a "$2" != "skt" -a "$2" != "lgu" -a "$2" != "all" ]; then
  echored "ERROR: You must specify correct build option : kt / skt / lgu / all"
  exit 1
fi   

echo ""
echocyan "Setting up defconfig"

make lw_defconfig

echo ""
echocyan "Building Kernel"

[ -e arch/arm/boot/zImage ] && mv arch/arm/boot/zImage arch/arm/boot/zImage.old
make -j"$JOBS"
if [ -e arch/arm/boot/zImage ]; then
  rm -f arch/arm/boot/zImage.old
else
  [ -e arch/arm/boot/zImage.old ] && mv arch/arm/boot/zImage.old arch/arm/boot/zImage
  echo ""
  echored "Build FAILED!"
  exit 1
fi

echo ""
echocyan "Building DT Image"

tools/dtbTool -o dt.img -s 4096 -p scripts/dtc/ arch/arm/boot/dts/
chmod a+r dt.img

echo ""
echocyan "Compressing ramdisk"

rm -f ramdisk/*.gz
cd ramdisk/kt
if [ ! -e data ]; then mkdir data dev proc sys system;fi
find . | cpio -o -H newc | gzip > ../initrd_kt.gz
cd ../skt
if [ ! -e data ]; then mkdir data dev proc sys system;fi
find . | cpio -o -H newc | gzip > ../initrd_skt.gz
cd ../lgu
if [ ! -e data ]; then mkdir data dev proc sys system;fi
find . | cpio -o -H newc | gzip > ../initrd_lgu.gz
cd ../..

if [ "$2" = "all" -o "$2" = "kt" ]; then
  echo ""
  echocyan "Building boot.img : KT"
  export variant=kt
  build_bootimg
fi
if [ "$2" = "all" -o "$2" = "skt" ]; then
  echo ""
  echocyan "Building boot.img : SKT"
  export variant=skt
  build_bootimg
fi
if [ "$2" = "all" -o "$2" = "lgu" ]; then
  echo ""
  echocyan "Building boot.img : LGU"
  export variant=lgu
  build_bootimg
fi

echo ""
echocyan "BUILD COMPLETE!"

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
  echored "ERROR: .config NOT FOUND"
fi

elif [ "$1" = "install" ]; then

if [ "$2" = "kt" ]; then
  export variant=kt
elif [ "$2" = "skt" ]; then
  export variant=skt
elif [ "$2" = "lgu" ]; then
  export variant=lgu
else
  echored "ERROR: You must specify correct install option : kt / skt / lgu"
  exit 1
fi
install_bootimg

else

echocyan "Usage: ./lw.sh [build all/kt/sk/lgu / clean / saveconfig / install kt/sk/lgu]"

fi
