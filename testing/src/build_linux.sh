#!/bin/bash
source ./build_env.sh
export EXTRAVERSION="_android_chroot_testing"

cp android_chroot_testing_defconfig linux/arch/arm64/configs
cd linux
make android_chroot_testing_defconfig
make -j4