PRODUCT_NAME := qemu_arm64
PRODUCT_DEVICE := qemu_arm64
PRODUCT_BRAND := Android
PRODUCT_MODEL := qemu-arm64
PRODUCT_MANUFACTURER := QEMU

$(call inherit-product, device/generic/qemu/shared/device.mk)

PRODUCT_COPY_FILES += \
	device/generic/qemu/prebuilts/arm64/android16-6.13.img:kernel \

QEMU_PREBUILTS := \
	device/generic/qemu/prebuilts/arm64/android16-6.13.img \
	device/generic/qemu/prebuilts/arm64/gbl.efi \

$(foreach f,$(QEMU_PREBUILTS),$(if $(wildcard $(f)),,\
	$(error $(f) is missing, run device/generic/qemu/build/scripts/fetch_release.sh prebuilts)))
