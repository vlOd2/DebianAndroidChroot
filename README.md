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

I recommend to use [this module](https://github.com/Magisk-Modules-Alt-Repo/BuiltIn-BusyBox) if you **don't have Busybox** and are using Magisk

# Instructions
For *instructions* on setting up a **basic** environment, click [here](INSTRUCTIONS_BASIC.md)
For *instructions* on setting up a **graphical** environment, click [here](INSTRUCTIONS_GUI.md)
For *instructions* on setting up an emulated **testing** environment, click [here](testing/README.md)
> [!IMPORTANT]
> You don't need to follow the testing instructions to use the environment on your Android device

# Alternatives
If you don't have a rooted device or a computer, you can use [proot](https://wiki.termux.com/wiki/PRoot)<br>
To quickly setup a Debian environment without any hassle, you can use [proot-distro](https://wiki.termux.com/wiki/PRoot#Installing_Linux_distributions)<br>
If you would like a pretty similar script to this one but for proot, you can use [debian-on-termux by sp4rkie](https://github.com/sp4rkie/debian-on-termux)