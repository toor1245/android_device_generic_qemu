#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PREBUILTS_DIR=$SCRIPT_DIR/../../prebuilts/arm64
PREBUILTS="android16-6.13.img gbl.efi"

usage() {
  echo "usage: $0 [-o RELEASE_DIR] [PRODUCT_OUT]"
  echo
  echo "Packs freshly built images and the prebuilts into release assets:"
  echo "  android.qcow2, emmc.qcow2, <prebuilt>.xz and SHA256SUMS."
  echo "PRODUCT_OUT defaults to \$ANDROID_PRODUCT_OUT, RELEASE_DIR to PRODUCT_OUT/release."
  exit 1
}

while getopts "o:h" opt; do
  case $opt in
    o) RELEASE_DIR=$OPTARG ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))

PRODUCT_OUT=${1:-$ANDROID_PRODUCT_OUT}
[ -n "$PRODUCT_OUT" ] || usage
RELEASE_DIR=${RELEASE_DIR:-$PRODUCT_OUT/release}

ANDROID_IMG=$PRODUCT_OUT/android.img
EMMC_IMG=$PRODUCT_OUT/rpmb.img

SGDISK=$(command -v "$ANDROID_HOST_OUT/bin/sgdisk" sgdisk | head -1)
for tool in "$SGDISK" qemu-img debugfs xz sha256sum; do
  command -v "$tool" >/dev/null || { echo "missing tool: ${tool:-sgdisk}" >&2; exit 1; }
done
for img in "$ANDROID_IMG" "$EMMC_IMG"; do
  [ -f "$img" ] || { echo "missing $img: build the product first" >&2; exit 1; }
done

booted() {
  echo "$1 was already booted ($2): rebuild the images before releasing" >&2
  exit 1
}

# Prints the first sector and the sector count of a GPT partition.
partition() {
  "$SGDISK" --print "$ANDROID_IMG" | awk -v n="$1" '$7 == n {print $2, $3 - $2 + 1}'
}

is_zero() {
  cmp -s -n "$(($3 * 512))" <(dd if="$1" bs=512 skip="$2" count="$3" status=none) /dev/zero
}

read -r MISC_START MISC_SECTORS <<< "$(partition misc)"
is_zero "$ANDROID_IMG" "$MISC_START" "$MISC_SECTORS" || booted "$ANDROID_IMG" "misc is written"

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

read -r META_START META_SECTORS <<< "$(partition metadata)"
dd if="$ANDROID_IMG" of="$TMP/metadata.img" bs=512 skip="$META_START" count="$META_SECTORS" status=none
META_FILES=$(debugfs -R "ls -p /" "$TMP/metadata.img" 2>/dev/null |
  awk -F/ 'NF > 1 && $6 != "." && $6 != ".." && $6 != "lost+found"')
[ -z "$META_FILES" ] || booted "$ANDROID_IMG" "metadata is populated"

is_zero "$EMMC_IMG" 0 "$(($(stat -c%s "$EMMC_IMG") / 512))" || booted "$EMMC_IMG" "eMMC is written"

mkdir -p "$RELEASE_DIR"
rm -f "$RELEASE_DIR"/*

echo "Converting $ANDROID_IMG..."
qemu-img convert -c -O qcow2 -o compression_type=zstd "$ANDROID_IMG" "$RELEASE_DIR/android.qcow2"
echo "Converting $EMMC_IMG..."
qemu-img convert -c -O qcow2 -o compression_type=zstd "$EMMC_IMG" "$RELEASE_DIR/emmc.qcow2"

for f in $PREBUILTS; do
  echo "Compressing $f..."
  xz -T0 -9 -c "$PREBUILTS_DIR/$f" > "$RELEASE_DIR/$f.xz"
done

(cd "$RELEASE_DIR" && sha256sum android.qcow2 emmc.qcow2 *.xz > SHA256SUMS)

echo
ls -l "$RELEASE_DIR"
echo
echo "Upload every file in $RELEASE_DIR as assets of a new GitHub release."
