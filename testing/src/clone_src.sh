#!/bin/bash
git clone --depth 1 https://git.busybox.net/busybox
wget https://www.kernel.org/pub/linux/kernel/v5.x/linux-5.4.295.tar.xz -O linux.tar.xz
mkdir -p linux
tar xfv linux.tar.xz -C linux --strip-components=1
rm linux.tar.xz