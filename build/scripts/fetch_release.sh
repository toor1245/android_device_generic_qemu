#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
PREBUILTS_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)/prebuilts/arm64
PREBUILTS="android16-6.13.img gbl.efi"
IMAGES="android.qcow2 emmc.qcow2"

REPO=${REPO:-toor1245/android_device_generic_qemu}
BASE_URL=${BASE_URL:-https://github.com/$REPO/releases}

usage() {
  echo "usage: $0 [-t TAG] [-o IMAGES_DIR] images|prebuilts|all"
  echo
  echo "Downloads release assets and checks their SHA-256."
  echo "  images     android.qcow2 and emmc.qcow2 into IMAGES_DIR (default: .)"
  echo "  prebuilts  the kernel and gbl.efi into prebuilts/arm64, needed by m"
  echo "Without -t, the release and checksums pinned in prebuilts/arm64/release.lock"
  echo "are used. With -t, the checksums come from the release's SHA256SUMS."
  exit 1
}

LOCK=$PREBUILTS_DIR/release.lock
TAG=
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

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

if [ -z "$TAG" ]; then
  [ -f "$LOCK" ] || { echo "missing $LOCK, pass -t TAG" >&2; exit 1; }
  TAG=$(awk '$1 == "tag" {print $2}' "$LOCK")
  grep -v '^tag ' "$LOCK" > "$TMP/SHA256SUMS"
fi
URL=$BASE_URL/download/$TAG

download() {
  echo "Downloading $1..."
  curl -fL -# --retry 3 -o "$TMP/$1" "$URL/$1"
  if [ "$1" != SHA256SUMS ]; then
    grep -q "  $1\$" "$TMP/SHA256SUMS" || { echo "$1 is not in SHA256SUMS" >&2; exit 1; }
    (cd "$TMP" && grep "  $1\$" SHA256SUMS | sha256sum -c --quiet -)
  fi
}

[ -f "$TMP/SHA256SUMS" ] || download SHA256SUMS

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
  mkdir -p "$PREBUILTS_DIR"
  for f in $PREBUILTS; do
    download "$f.xz"
    xz -dc "$TMP/$f.xz" > "$TMP/$f"
    mv "$TMP/$f" "$PREBUILTS_DIR/$f"
  done
fi
