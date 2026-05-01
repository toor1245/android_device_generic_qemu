TARGET_BOARD_PLATFORM := qemu_arm64
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_VARIANT := generic
TARGET_CPU_ABI := arm64-v8a

-include device/generic/qemu/shared/BoardConfig.mk

#
# Bootconfig
#

BOARD_BOOTCONFIG += androidboot.boot_devices=a003c00.virtio_mmio
