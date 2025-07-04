# DebianAndroidChroot
Easily bootstrap a Debian 12 chroot environment for a **rooted** Android device
> [!CAUTION]
> These scripts are provided under no-warranty and I am not responsible for any damages<br>
> YOU MAY BRICK YOUR DEVICE IF YOU'RE NOT CAREFUL!!!

> [!NOTE]  
> If you don't have a rooted Android device, see below for alternatives

# Prerequisites
- A Linux environment (only tested with Debian 12 inside WSL2)
- A rooted Android device (only tested on Android 11)
- A functional Busybox install on said device
- Termux and the root-repo installed

> [!NOTE]  
> If you don't have a Linux environment and are on Windows 10/11, you can use WSL2 instead of a VM

I recommend to use [this module](https://github.com/Magisk-Modules-Alt-Repo/BuiltIn-BusyBox) if you are using Magisk

# Basic environment

## Install
1. Bootstrap and configure Debian (`bootstrap_debian.sh`)
- You will be dropped into a minimal root shell at the end, you can just exit or install anything extra
2. Create the rootfs image (`make_image.sh`)
- After you are done, you can delete the `out/rootfs` *folder* to save on disk space
3. Create a `/data/chroot` folder on your Android device
4. Copy the rootfs image (it's under `out/rootfs.img`) to that folder
5. Copy the scripts inside `android_scripts` to that folder

You are now ready to start the environment

## Usage
1. Mount the environment when you are ready (`mount.sh`)
- You might get warnings about TMPDIR not being set, you can safely ignore them
2. Login into the environment (`login.sh`)
- You may specify a username like so: `login.sh username` (it will default to root)
3. Use the environment however you like, bear in mind that services don't really work
4. When you are done with it, un-mount the environment (`unmount.sh`)
- This step may have some problems on some devices
- If you see any errors, you should probably reboot and make an issue report

# Testing steps
> [!IMPORTANT]
> You don't need to do these steps to use the environment on your Android device<br>
> This is only meant for testing and debugging on a desktop computer

> [!CAUTION]
> The testing scripts do not perform any dependency checking<br>
> Make sure to have the proper tools installed to cross-compile the Linux kernel and run QEMU

Follow the regular steps, and...
1. Go in the `testing` directory
2. Make a test image (`make_test_image.sh`)
3. Go in the `src` directory
4. Clone the busybox and Linux 5.4 source code (`clone_src.sh`)
5. Build busybox and the initramfs (`build_initramfs.sh`)
6. Build the testing kernel (`build_linux.sh`)
7. Package the initramfs (`package_initramfs.sh`)
8. Go back in the `testing` directory and run QEMU (`start_qemu.sh`)

# Alternatives
If you don't have a rooted device or a computer, you can use [proot](https://wiki.termux.com/wiki/PRoot)<br>
To quickly setup a Debian environment without any hasle, you can use [proot-distro](https://wiki.termux.com/wiki/PRoot#Installing_Linux_distributions)<br>
If you would like a pretty similar script to this one but for proot, you can use [debian-on-termux by sp4rkie](https://github.com/sp4rkie/debian-on-termux)