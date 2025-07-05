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