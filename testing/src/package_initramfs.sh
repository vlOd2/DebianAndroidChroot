#!/bin/bash
cp initramfs_init initramfs/init
echo "#!/bin/sh" > initramfs/bin/bash
echo "/bin/sh \"\$@\"" >> initramfs/bin/bash
chmod +x initramfs/bin/bash
cd initramfs
find . -print0 | cpio --null -ov --format=newc | gzip -9 > ../initramfs.cpio.gz
cd ..