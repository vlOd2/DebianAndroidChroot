#!/bin/bash
QEMU_ARGS=(
	# System
	--accel tcg,thread=multi
	-M virt,virtualization=on
	-cpu cortex-a57 -smp 4
	-m 1024M
	-bios /usr/share/qemu-efi-aarch64/QEMU_EFI.fd
	
	# Hardware
	-device virtio-gpu-pci
	-device virtio-mouse-pci
	-device virtio-keyboard-pci
	-device virtio-scsi-pci

	# Kernel options
	-kernel src/linux/arch/arm64/boot/Image.gz
	-initrd src/initramfs.cpio.gz
	-append "console=ttyAMA0 console=tty0"
	
	# Testing disk
	-drive if=none,file=./disk/disk.img,format=raw,id=disk
	-device scsi-hd,drive=disk
	
	# Network
	-netdev user,id=net0
	-device virtio-net-pci,netdev=net0
)

qemu-system-aarch64 "${QEMU_ARGS[@]}"