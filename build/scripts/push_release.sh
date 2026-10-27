#!/bin/bash

set -e

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
DEVICE_DIR=$(cd "$SCRIPT_DIR/../.." && pwd)
LOCK=$DEVICE_DIR/prebuilts/arm64/release.lock
ASSETS="android.qcow2 emmc.qcow2 android16-6.13.img.xz gbl.efi.xz"

REPO=${REPO:-toor1245/android_device_generic_qemu}

usage() {
  echo "usage: $0 [-d RELEASE_DIR] [-n NOTES_FILE] TAG"
  echo
  echo "Uploads the assets made by mkrelease.sh as a draft GitHub release and pins"
  echo "them in prebuilts/arm64/release.lock. Publish the draft on GitHub after"
  echo "checking it, and commit release.lock."
  echo "RELEASE_DIR defaults to \$ANDROID_PRODUCT_OUT/release. NOTES_FILE is appended"
  echo "to the release notes, e.g. the kernel and GBL sources the binaries come from."
  exit 1
}

while getopts "d:n:h" opt; do
  case $opt in
    d) RELEASE_DIR=$OPTARG ;;
    n) NOTES_FILE=$OPTARG ;;
    *) usage ;;
  esac
done
shift $((OPTIND - 1))
[ $# -eq 1 ] || usage
TAG=$1

[ -n "$ANDROID_PRODUCT_OUT" ] || [ -n "$RELEASE_DIR" ] || usage
RELEASE_DIR=${RELEASE_DIR:-$ANDROID_PRODUCT_OUT/release}

fail() {
  echo "$1" >&2
  exit 1
}

command -v gh >/dev/null || fail "missing gh, install the GitHub CLI and run gh auth login"
gh auth status >/dev/null 2>&1 || fail "gh is not logged in, run gh auth login"

[ -f "$RELEASE_DIR/SHA256SUMS" ] || fail "missing $RELEASE_DIR/SHA256SUMS, run mkrelease.sh first"
for f in $ASSETS; do
  grep -q "  $f\$" "$RELEASE_DIR/SHA256SUMS" || fail "$f is not in $RELEASE_DIR/SHA256SUMS"
done
(cd "$RELEASE_DIR" && sha256sum -c --quiet SHA256SUMS) || fail "$RELEASE_DIR does not match its SHA256SUMS"
[ -z "$NOTES_FILE" ] || [ -f "$NOTES_FILE" ] || fail "missing $NOTES_FILE"

if gh release view "$TAG" --repo "$REPO" >/dev/null 2>&1; then
  fail "release $TAG already exists, releases are never replaced"
fi

COMMIT=$(git -C "$DEVICE_DIR" rev-parse HEAD)
[ -z "$(git -C "$DEVICE_DIR" status --porcelain)" ] ||
  echo "warning: $DEVICE_DIR has uncommitted changes, the notes name $COMMIT" >&2

TARGET=()
if [ -n "$(git -C "$DEVICE_DIR" branch -r --contains "$COMMIT" 2>/dev/null)" ]; then
  TARGET=(--target "$COMMIT")
else
  echo "warning: $COMMIT is not pushed, the tag is created from the default branch on publish" >&2
fi

NOTES=$(mktemp)
trap 'rm -f "$NOTES"' EXIT
{
  echo "QEMU arm64 Android images and prebuilts for GBL on LK."
  echo
  echo "Built from device/generic/qemu $COMMIT."
  echo "Signed with AOSP test keys, for development only."
  echo
  echo "Fetch with \`build/scripts/fetch_release.sh -t $TAG images|prebuilts|all\`."
  if [ -n "$NOTES_FILE" ]; then
    echo
    cat "$NOTES_FILE"
  fi
  echo
  echo '```'
  cat "$RELEASE_DIR/SHA256SUMS"
  echo '```'
} > "$NOTES"

FILES=()
for f in $ASSETS SHA256SUMS; do
  FILES+=("$RELEASE_DIR/$f")
done

gh release create "$TAG" "${FILES[@]}" --repo "$REPO" --draft --title "$TAG" \
  --notes-file "$NOTES" "${TARGET[@]}"

{ echo "tag $TAG"; cat "$RELEASE_DIR/SHA256SUMS"; } > "$LOCK"

echo
echo "Draft release $TAG created. Next:"
echo "  1. Check and publish it: https://github.com/$REPO/releases"
echo "  2. Commit prebuilts/arm64/release.lock"
