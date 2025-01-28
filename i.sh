#!/bin/bash
#set -e
## Copy this script inside the kernel directory
CLANGDIR="/workspace/build/clang"
export KBUILD_BUILD_USER=Ndrα
export KBUILD_BUILD_HOST=ND-Irαwαn
LINKER="lld"
DIR=$(readlink -f .)
MAIN=$(readlink -f ${DIR}/..)
export PATH="$MAIN/clang/bin:$PATH"
export ARCH=arm64
export SUBARCH=arm64

#
rm -rf out
rm -rf compile.log

#
mkdir -p out
mkdir out/Ndra

KERNEL_DIR=$(pwd)
ZIMAGE_DIR="$KERNEL_DIR/out/arch/arm64/boot"
# Speed up build process
MAKE="./makeparallel"
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'

# Function to revert modifications

revert_modifications() {
  if [ "$choice" = "miui" ]; then
    if [ "$device" = "apollo" ]; then
      sed -i 's/qcom,mdss-pan-physical-width-dimension = <700>;$/qcom,mdss-pan-physical-width-dimension = <70>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
      sed -i 's/qcom,mdss-pan-physical-height-dimension = <1540>;$/qcom,mdss-pan-physical-height-dimension = <155>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
    elif [ "$device" = "alioth" ]; then
      sed -i 's/qcom,mdss-pan-physical-width-dimension = <700>;$/qcom,mdss-pan-physical-width-dimension = <70>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
      sed -i 's/qcom,mdss-pan-physical-height-dimension = <1540>;$/qcom,mdss-pan-physical-height-dimension = <155>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
    fi
  fi
  git checkout arch/arm64/boot/dts/vendor/qcom/dsi-panel-* &>/dev/null
}


echo -e "$blue***********************************************"
echo "          BUILDING KERNEL          "
echo -e "***********************************************$nocol"

# Prompt for device choice
read -p "Choose device (apollo/alioth): " device
if [ "$device" = "apollo" ]; then
  KERNEL_DEFCONFIG=apollo_defconfig
  DEVICE_NAME1="apollo"
  DEVICE_NAME2="apollon"
  IS_SLOT_DEVICE=0
  
  # Remove vendor_boot block for apollo
  VENDOR_BOOT_LINES_REMOVED=1
else
  KERNEL_DEFCONFIG=alioth_defconfig
  DEVICE_NAME1="alioth"
  DEVICE_NAME2="aliothin"
  IS_SLOT_DEVICE=1
  VENDOR_BOOT_LINES_REMOVED=0
fi

# Prompt for MIUI or AOSP
read -p "Do you want MIUI or AOSP? (miui/aosp): " choice
if [ "$choice" = "miui" ]; then
  # Modify the dimensions for MIUI
  if [ "$device" = "apollo" ]; then
    sed -i 's/qcom,mdss-pan-physical-width-dimension = <70>;$/qcom,mdss-pan-physical-width-dimension = <700>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
    sed -i 's/qcom,mdss-pan-physical-height-dimension = <155>;$/qcom,mdss-pan-physical-height-dimension = <1540>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-j3s-37-02-0a-dsc-video.dtsi
  elif [ "$device" = "alioth" ]; then
    sed -i 's/qcom,mdss-pan-physical-width-dimension = <70>;$/qcom,mdss-pan-physical-width-dimension = <700>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
    sed -i 's/qcom,mdss-pan-physical-height-dimension = <155>;$/qcom,mdss-pan-physical-height-dimension = <1540>;/' arch/arm64/boot/dts/vendor/qcom/dsi-panel-k11a-38-08-0a-dsc-cmd.dtsi
  fi
fi

# Remove vendor_boot block if necessary
if [ "$VENDOR_BOOT_LINES_REMOVED" -eq 1 ]; then
  sed -i '/## vendor_boot shell variables/,/## end vendor_boot install/d' anykernel/anykernel.sh
fi

# kernel-Compilation

make $KERNEL_DEFCONFIG O=out CC=clang
make -j$(nproc --all) O=out \
  CC=clang \
  ARCH=arm64 \
  CROSS_COMPILE=aarch64-linux-gnu- \
  NM=llvm-nm \
  OBJDUMP=llvm-objdump \
  STRIP=llvm-strip

TIME="$(date "+%Y%m%d-%H%M%S")"
if [ $? -ne 0 ]
then
    echo "Build failed"
else
    echo "Build succesful"
    cp out/arch/arm64/boot/dtbo.img out/outputs/Ndra/dtbo.img
    cp out/arch/arm64/boot/Image.gz out/outputs/Ndra/Image.gz
    cp out/arch/arm64/boot/dtb out/Ndra/dtb
fi
echo $TIME
