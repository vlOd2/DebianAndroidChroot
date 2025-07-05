#!/bin/bash
source ./build_env.sh

cd busybox
make defconfig
sleep 1
sed "/CONFIG_STATIC/s/.*/CONFIG_STATIC=y/" -i .config
sed "/CONFIG_STATIC_LIBGCC/s/.*/CONFIG_STATIC_LIBGCC=y/" -i .config
make -j4

mkdir -p ../initramfs/{dev,proc,sys}
mkdir -p ../initramfs/data/chroot
make CONFIG_PREFIX="../initramfs" install
rm ../initramfs/linuxrc