# android_device_generic_qemu

```shell
source build/envsetup.sh
lunch qemu_arm64-cp2a-eng
m
```

## Release

Packs a freshly built, never booted product into `$ANDROID_PRODUCT_OUT/release`:

```shell
device/generic/qemu/build/scripts/mkrelease.sh
```

Upload every file in that directory as assets of a GitHub release.

## Fetch

Downloads the latest release and checks it against `SHA256SUMS`:

```shell
# kernel and gbl.efi into prebuilts/arm64, needed by m
device/generic/qemu/build/scripts/fetch_release.sh prebuilts
# ready to run android.qcow2 and emmc.qcow2
device/generic/qemu/build/scripts/fetch_release.sh -o images images
```

Use `-t TAG` for a specific release.
