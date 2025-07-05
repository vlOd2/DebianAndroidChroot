# Basic environment
Instructions for getting a basic (CLI-only) chroot environment

## Install
1. Bootstrap and configure Debian (`bootstrap_debian.sh`)
- You will be dropped into a minimal root shell at the end, you can just exit or install anything extra
> [!TIP]
> You will be asked some questions interactively, so make sure to pay attention to the bootstrap process
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