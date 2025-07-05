# Basic environment
Instructions for creating and using a basic (CLI-only) chroot environment

## Install
1. Bootstrap and configure Debian (`bootstrap_debian.sh`)
- You will be asked some questions interactively, so make sure to pay attention to the bootstrap process
- You will be then dropped into a minimal root shell at the end, you can just exit or install anything extra

> [!WARNING]
> The image has a limited size by default, so it's better to install any packages later<br>
> For more information and an example on growing the image size check below

2. Create the rootfs image (`make_image.sh`)
- After you are done, you can delete the `out/rootfs` *folder* to save on disk space
3. Create a `/data/chroot` folder on your Android device
4. Copy the rootfs image (it's under `out/rootfs.img`) to that folder
5. Copy the scripts inside `android_scripts` (excluding `extras`) to that folder

You are now ready to start the environment

## Usage
All of these steps must be done inside a **root** shell
1. Navigate to `/data/chroot`
2. Mount the environment (`mount.sh`)
- You might get warnings about TMPDIR not being set, you can safely ignore them
3. Login into the environment (`login.sh`)
- You may specify a username like so: `login.sh username` (it will default to root)
4. Use the environment however you like, bear in mind that services don't really work
5. When you are done with it, un-mount the environment (`unmount.sh`)
- This step may have some problems on some devices
- If you see any errors, you should probably reboot and make an issue report (make sure to include device information!)

# Growing the image
As previously mentioned, the default size of the rootfs image is **4GB**<br>
The reason is so that it doesn't take forever to transfer to the device<br>
It is also more than enough for a minbase Debian install with the additional packages included

It is recommended that you grow the image *after* copying it to your Android device<br>
> [!IMPORTANT]  
> Make sure to *un-mount* the environment **before** doing any operations on the image

Example on growing the image by 2GB for 6GB in total:
```
# cd /data/chroot
# dd if=/dev/zero bs=1024M count=2 >> rootfs.img
# e2fsck -f rootfs.img
# resize2fs rootfs.img
```

You can replace the `2` in `count=2` with how many GBs you want to grow
> [!TIP]
> You shouldn't grow to the max amount you can, instead grow as needed

# Swap space
The rootfs comes with a 2GB swap file by default (located in the root folder)<br>
You can either delete it if you have enough RAM to save on space, or allocate more if needed

> [!NOTE]  
> The mount scripts will correctly handle a missing/larger swap file

Example on deleting the swap space (inside *Debian* as **root**):
```
# swapoff /swapfile
# rm /swapfile
```

Example on allocating more swap space (inside *Debian* as **root**):
```
# swapoff /swapfile
# rm /swapfile
# dd if=/dev/zero of=/swapfile bs=1024M count=4
# mkswap /swapfile
# swapon /swapfile
```

You can replace the `4` in `count=4` with how many GBs you want to grow
> [!TIP]
> Swap space should usually be half of or equal to the amount of RAM you have