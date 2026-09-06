$(call inherit-product, $(SRC_TARGET_DIR)/product/core_no_zygote.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/generic_ramdisk.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/virtual_ab_ota/vabc_features.mk)

PRODUCT_VIRTUAL_AB_COMPRESSION_METHOD := lz4
PRODUCT_VIRTUAL_AB_COW_VERSION := 3
PRODUCT_VIRTUAL_AB_COMPRESSION_FACTOR := 65536

PRODUCT_COPY_FILES += \
    device/generic/qemu/shared/fstab.qemu:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/first_stage_ramdisk/fstab.qemu \
    device/generic/qemu/shared/fstab.qemu:$(TARGET_COPY_OUT_VENDOR_RAMDISK)/fstab.qemu \
    device/generic/qemu/shared/fstab.qemu:$(TARGET_COPY_OUT_RAMDISK)/fstab.qemu \
    device/generic/qemu/shared/fstab.qemu:$(TARGET_COPY_OUT_RAMDISK)/first_stage_ramdisk/fstab.qemu \
    device/generic/qemu/shared/fstab.qemu:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.qemu \
    device/generic/qemu/shared/init.qemu.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.qemu.rc \

TARGET_RECOVERY_FSTAB := device/generic/qemu/shared/fstab.qemu

SKIP_BOOT_JARS_CHECK ?= true

PRODUCT_FULL_TREBLE_OVERRIDE := true

PRODUCT_HOST_PACKAGES += \
    adb \
    mke2fs \
    sgdisk \
    one-true-awk \
    lpdump \
    mkdtimg \
    dtc \
    mtools \
    newfs_msdos \

PRODUCT_PACKAGES += \
    aflags \
    aconfigd-system \
    apexd \
    cgroups.json \
    casefolding_remover \
    dhcpdbg \
    e2fsck \
    init.environ.rc \
    init_vendor \
    init_system \
    libbinder \
    libc.bootstrap \
    libdl.bootstrap \
    libdl_android.bootstrap \
    libm.bootstrap \
    libstdc++ \
    linker \
    linker64 \
    logcat \
    logd \
    logwrapper \
    remount \
    reboot \
    system-build.prop \
    task_profiles.json \
    tombstoned \
    toolbox \
    toybox \
    odsign \
    selinux_policy \
    sh \
    su \
    servicemanager \
    sanitizer.libraries.txt \
    vdc \
    vold \
    lshal \
    linker.vendor_ramdisk \

PRODUCT_PACKAGES += \
    hwservicemanager \
    android.hidl.allocator@1.0-service \

PRODUCT_PACKAGES += \
    com.android.runtime \
    com.android.adbd \
    com.android.tethering \

# Recovery packages
PRODUCT_PACKAGES += \
    recovery \
    init_second_stage.recovery \
    ld.config.recovery.txt \
    linker.recovery \
    shell_and_utilities_recovery \
    adbd.recovery \
    servicemanager.recovery \
    cgroups.recovery.json \
    otacerts.recovery \
    watchdogd.recovery \
    resize2fs.vendor_ramdisk \
    tune2fs.vendor_ramdisk \

PRODUCT_COPY_FILES += \
    device/generic/qemu/shared/init.recovery.qemu.rc:$(TARGET_COPY_OUT_RECOVERY)/root/init.recovery.qemu.rc

# OTA packages
PRODUCT_PACKAGES += \
    update_engine \
    update_engine_sideload \
    update_verifier \
    bootctl \
    com.android.hardware.boot \

PRODUCT_USE_DYNAMIC_PARTITIONS := true

# Keymint
PRODUCT_PACKAGES += \
    com.android.hardware.keymint.rust_nonsecure \
    keystore2 \
    com.android.i18n \
    com.android.os.statsd \

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.keystore.app_attest_key.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.keystore.app_attest_key.xml \

# VINTF stuff for system and vendor (no product / odm / system_ext / etc.)
PRODUCT_PACKAGES += \
    system_compatibility_matrix.xml \
    system_manifest.xml \
    vendor_compatibility_matrix.xml \
    vendor_manifest.xml \

# Creates metadata partition mount point under root for
# the devices with metadata partition
BOARD_USES_METADATA_PARTITION := true

PRODUCT_ENABLE_UFFD_GC := false

DEVICE_MANIFEST_FILE := device/generic/qemu/shared/manifest.xml
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false
