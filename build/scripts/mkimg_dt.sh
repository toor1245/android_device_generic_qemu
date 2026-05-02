#!/bin/bash

set -e

DEVICE_PATH=device/generic/qemu
TARGET_DEVICE=$3

# Tools
HOST_OUT=$1/bin
MKDTIMG=$HOST_OUT/mkdtimg
DTC=$HOST_OUT/dtc

# Images
PRODUCT_OUT=$2
DTS="${DEVICE_PATH}/fdts/${TARGET_DEVICE}.dts"
TEMP_DTB="${PRODUCT_OUT}/dtbs/${TARGET_DEVICE}.dtb"
DTB_IMG="${PRODUCT_OUT}/${TARGET_DEVICE}_dtb.img"

mkdir -p $PRODUCT_OUT/dtbs

echo "Compiling dts to dtb"
$DTC -I dts -O dtb -o "$TEMP_DTB" "$DTS"

echo "Creating ${TARGET_DEVICE}_dtb.img..."
$MKDTIMG create "$DTB_IMG" "$TEMP_DTB"

echo "Verifying image structure:"
$MKDTIMG dump "$DTB_IMG"
