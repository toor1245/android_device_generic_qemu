#!/bin/bash

set -e

# Tools
HOST_OUT=$1/bin
SGDISK=$HOST_OUT/sgdisk
MKE2FS=$HOST_OUT/mke2fs
MFTOOLS=$HOST_OUT/mtools
MCOPY=$HOST_OUT/mcopy
MFORMAT=$HOST_OUT/mformat
TOYBOX=$HOST_OUT/toybox
AWK=$HOST_OUT/one-true-awk

# Scripts
DEVICE_PATH=device/generic/qemu/build/scripts
MKEMMC="$DEVICE_PATH/mkemmc.sh"

# Images
PRODUCT_OUT=$2

BOOT_IMG=$PRODUCT_OUT/boot.img
INIT_BOOT_IMG=$PRODUCT_OUT/init_boot.img
VENDOR_BOOT_IMG=$PRODUCT_OUT/vendor_boot.img

VBMETA_IMG=$PRODUCT_OUT/vbmeta.img
VBMETA_SYSTEM_IMG=$PRODUCT_OUT/vbmeta_system.img
VBMETA_VENDOR_IMG=$PRODUCT_OUT/vbmeta_vendor.img
SUPER_IMG=$PRODUCT_OUT/super.img
USERDATA_IMG=$PRODUCT_OUT/userdata.img
METADATA_IMG=$PRODUCT_OUT/metadata.img
GBL_EFI=device/generic/qemu/prebuilts/arm64/gbl.efi
MY_EFI_APP_EFI=device/generic/qemu/prebuilts/arm64/MyEfiApp.efi
MY_SNP_APP_EFI=device/generic/qemu/prebuilts/arm64/MySnpApp.efi
SNP_SERVER_TEST_EFI=device/generic/qemu/prebuilts/arm64/SnpServerTest.efi

ANDROID_ESP_IMG=$PRODUCT_OUT/android_esp.img

OUT_IMG=$PRODUCT_OUT/android.img
ANDROID_EMMC_IMG=$PRODUCT_OUT/android_emmc.img

dd if=/dev/zero of=$METADATA_IMG bs=1M count=16
dd if=/dev/zero of=$ANDROID_ESP_IMG bs=1M count=64
dd if=/dev/zero of=$OUT_IMG bs=1M count=10240

$MKE2FS -t ext4 -b 4096 -F $METADATA_IMG

echo "Ensuring mformat symlink..."
ln -sf mtools "$MFORMAT"

$MFORMAT -i $ANDROID_ESP_IMG -v "ESP" -F
$MCOPY -i $ANDROID_ESP_IMG $GBL_EFI ::/gbl.efi
$MCOPY -i $ANDROID_ESP_IMG $MY_EFI_APP_EFI ::/MyEfiApp.efi
$MCOPY -i $ANDROID_ESP_IMG $MY_SNP_APP_EFI ::/MySnpApp.efi
$MCOPY -i $ANDROID_ESP_IMG $SNP_SERVER_TEST_EFI ::/SnpServerTest.efi

$SGDISK \
  --new=1:2048:+1M     --change-name=1:"vbmeta_a" \
  --new=2:0:+1M        --change-name=2:"vbmeta_b" \
  --new=3:0:+64M       --change-name=3:"boot_a" \
  --new=4:0:+64M       --change-name=4:"boot_b" \
  --new=5:0:+8M        --change-name=5:"init_boot_a" \
  --new=6:0:+8M        --change-name=6:"init_boot_b" \
  --new=7:0:+64M       --change-name=7:"vendor_boot_a" \
  --new=8:0:+64M       --change-name=8:"vendor_boot_b" \
  --new=9:0:+1M        --change-name=9:"vbmeta_system_a" \
  --new=10:0:+1M       --change-name=10:"vbmeta_system_b" \
  --new=11:0:+1M       --change-name=11:"vbmeta_vendor_a" \
  --new=12:0:+1M       --change-name=12:"vbmeta_vendor_b" \
  --new=13:0:+1M       --change-name=13:"misc" \
  --new=14:0:+16M      --change-name=14:"metadata" \
  --new=15:0:+64M      --change-name=15:"android_esp_a" \
  --new=16:0:+64M      --change-name=16:"android_esp_b" \
  --new=17:0:+8500M    --change-name=17:"super" \
  --new=18:0:0         --change-name=18:"userdata" \
  $OUT_IMG

write_to_partition() {
  local PART_NUM=$1
  local IMG=$2
  local START_SECTOR=$($SGDISK --print $OUT_IMG | $AWK -v p=$PART_NUM '$1 == p {print $2}')

  echo "Writing $IMG to partition $PART_NUM..."
  dd if=$IMG of=$OUT_IMG bs=512 seek=$START_SECTOR conv=notrunc
}

write_to_partition 1 $VBMETA_IMG
write_to_partition 3 $BOOT_IMG
write_to_partition 5 $INIT_BOOT_IMG
write_to_partition 7 $VENDOR_BOOT_IMG
write_to_partition 9 $VBMETA_SYSTEM_IMG
write_to_partition 11 $VBMETA_VENDOR_IMG
write_to_partition 14 $METADATA_IMG
write_to_partition 15 $ANDROID_ESP_IMG
write_to_partition 17 $SUPER_IMG
write_to_partition 18 $USERDATA_IMG

$SGDISK --print $OUT_IMG

$MKEMMC -r /dev/zero:16M $OUT_IMG $ANDROID_EMMC_IMG
