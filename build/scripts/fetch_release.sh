#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PREBUILTS_DIR=$SCRIPT_DIR/../../prebuilts/arm64
PREBUILTS="android16-6.13.img gbl.efi"
IMAGES="android.qcow2 emmc.qcow2"

REPO=${REPO:-toor1245/android_device_generic_qemu}
BASE_URL=${BASE_URL:-https://github.com/$REPO/releases}

usage() {
  echo "usage: $0 [-t TAG] [-o IMAGES_DIR] images|prebuilts|all"
  echo
  echo "Downloads release assets and checks them against SHA256SUMS."
  echo "  images     android.qcow2 and emmc.qcow2 into IMAGES_DIR (default: .)"
  echo "  prebuilts  the kernel and gbl.efi into prebuilts/arm64, needed by m"
  echo "TAG defaults to the latest release."
  exit 1
}

TAG=latest
IMAGES_DIR=.
while getopts "t:o:h" opt; do
  case $opt in
    t) TAG=$OPTARG ;;
    o) IMAGES_DIR=$OPTARG ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -eq 1 ] || usage

case $1 in
  images) WANT_IMAGES=1 ;;
  prebuilts) WANT_PREBUILTS=1 ;;
  all) WANT_IMAGES=1; WANT_PREBUILTS=1 ;;
  *) usage ;;
esac

if [ "$TAG" = latest ]; then
  URL=$BASE_URL/latest/download
else
  URL=$BASE_URL/download/$TAG
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

download() {
  echo "Downloading $1..."
  curl -fL -# --retry 3 -o "$TMP/$1" "$URL/$1"
  if [ "$1" != SHA256SUMS ]; then
    grep -q "  $1\$" "$TMP/SHA256SUMS" || { echo "$1 is not in SHA256SUMS" >&2; exit 1; }
    (cd "$TMP" && grep "  $1\$" SHA256SUMS | sha256sum -c --quiet -)
  fi
}

download SHA256SUMS

if [ -n "$WANT_IMAGES" ]; then
  mkdir -p "$IMAGES_DIR"
  for f in $IMAGES; do
    download "$f"
    mv "$TMP/$f" "$IMAGES_DIR/$f"
  done
  echo
  echo "Run QEMU on overlays, so $IMAGES_DIR keeps the factory images:"
  for f in $IMAGES; do
    echo "  qemu-img create -f qcow2 -b $f -F qcow2 $IMAGES_DIR/${f%.qcow2}-run.qcow2"
  done
fi

if [ -n "$WANT_PREBUILTS" ]; then
  for f in $PREBUILTS; do
    download "$f.xz"
    xz -dc "$TMP/$f.xz" > "$PREBUILTS_DIR/$f"
  done
fi
