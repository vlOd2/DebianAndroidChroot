# Basic environment
Instructions for creating and using a basic (CLI-only) chroot environment

> [!TIP]
> Additional useful information is also available below, such as growing the image size or creating a user

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
5. Copy the scripts using the helper (`copy_scripts.sh`)

You are now ready to start the environment<br>

## Usage
All of these steps must be done inside a **root** shell
1. Navigate to `/data/chroot`
2. Mount the environment (`mount.sh`)
3. Login into the environment (`login.sh`)
- You may specify a username like so: `login.sh username` (it will default to root)
4. Use the environment however you like, bear in mind that *services* won't be autostarted, and systemd is unavailable
5. When you are done with it, un-mount the environment (`unmount.sh`)
- This step may have some problems on some devices
- If you see any errors, you should probably reboot and make an issue report (make sure to include device information!)

# Growing the image
As previously mentioned, the default size of the rootfs image is **4GB**<br>
The reason is so that it doesn't take forever to transfer to the device<br>
It is also more than enough for a minbase Debian install with the additional packages included

If you want to grow the image, it is recommended that you do so *after* copying it to your Android device<br>
> [!IMPORTANT]  
> Make sure to *un-mount* the environment **before** doing any operations on the image

Example on growing the image by 2GB for 6GB in total:
```
(termux) # cd /data/chroot
(termux) # dd if=/dev/zero bs=1024M count=2 >> rootfs.img
(termux) # e2fsck -f rootfs.img
(termux) # resize2fs rootfs.img
```

You can replace the `2` in `count=2` with how many GBs you want to grow
> [!TIP]
> You shouldn't grow to the max amount space available on the device, instead grow as needed

# Swap space
The rootfs comes with a 2GB swap file by default (located in the root folder)<br>
You can either delete it if you have enough RAM to save on space, or allocate more if needed<br>

> [!NOTE]  
> The mount scripts will correctly handle a missing/larger swap file

Example on deleting the swap space (inside *Debian* as **root**):
```
(debian) # swapoff /swapfile
(debian) # rm /swapfile
```

Example on allocating more swap space (inside *Debian* as **root**):
```
(debian) # swapoff /swapfile
(debian) # rm /swapfile
(debian) # dd if=/dev/zero of=/swapfile bs=1024M count=4
(debian) # mkswap /swapfile
(debian) # swapon /swapfile
```

You can replace the `4` in `count=4` with how many GBs you want to grow
> [!TIP]
> Swap space should usually be half of or equal to the amount of RAM you have

# Creating a user
Creating a user is pretty similar to how you would do it on a regular Debian system<br>

> [!IMPORTANT]  
> You need to add the user to the `aid_inet` and `aid_net_raw` groups to be able to use the internet

Example for creating the user `john` with sudo privileges and access to the internet
```
(termux) # ./login.sh
(debian) # adduser john
(debian) # usermod -G aid_inet,aid_net_raw,sudo -a john
(debian) # exit
(termux) # ./login.sh john
(debian) $ whoami
```

## Android groups
Android has a few special users and groups that allow a user to use certain features<br>
You can see the full list of them [here](https://android.googlesource.com/platform/system/core/+/master/libcutils/include/private/android_filesystem_config.h)<br>

> [!WARNING]  
> There are a bunch of *users* listed there in too<br>
> You can search what something there does online if you aren't sure<br>

When creating a rootfs, the following *groups* are created and assigned their proper GID:
- aid_net_bt_admin
- aid_net_bt
- aid_inet
- aid_net_raw
- aid_net_admin
- aid_net_bw_stats
- aid_net_bw_acct
- aid_readproc
- aid_wakelock
- aid_uhid
- aid_readtracefs

The root user is made a member of all of these while creating a rootfs as well<br>
The most interesting out of all of these are `aid_inet` and `aid_net_raw`, 

as they allow a user to create AF_INET/AF_INET6 and raw sockets (i.e make network connections)
