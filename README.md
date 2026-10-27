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

Then upload it as a draft GitHub release and pin it in `prebuilts/arm64/release.lock`
(needs the GitHub CLI, logged in with `gh auth login`):

```shell
device/generic/qemu/build/scripts/push_release.sh qemu-arm64-YYYY-MM-DD
```

Check and publish the draft on GitHub, then commit `release.lock`.

## Fetch

Downloads the release pinned in `prebuilts/arm64/release.lock` and checks it
against the checksums there:

```shell
# kernel and gbl.efi into prebuilts/arm64, needed by m
device/generic/qemu/build/scripts/fetch_release.sh prebuilts
# ready to run android.qcow2 and emmc.qcow2
device/generic/qemu/build/scripts/fetch_release.sh -o images images
```

Use `-t TAG` for a specific release.
