ifneq ($(filter qemu%, $(TARGET_DEVICE)),)

DEVICE_PATH := device/generic/qemu
DTB_GEN_SCRIPT := $(DEVICE_PATH)/build/scripts/mkimg_dt.sh

QEMU_DTB_IMG := $(PRODUCT_OUT)/$(TARGET_DEVICE)_dtb.img
QEMU_DTS_SRC := $(DEVICE_PATH)/fdts/$(TARGET_DEVICE).dts

$(QEMU_DTB_IMG): $(QEMU_DTS_SRC)
	@echo "Generating DTB image for $(TARGET_DEVICE)..."
	$(DTB_GEN_SCRIPT) $(HOST_OUT) $(PRODUCT_OUT) $(TARGET_DEVICE)

$(INSTALLED_VENDOR_BOOTIMAGE_TARGET): $(QEMU_DTB_IMG)

.PHONY: androidimage
androidimage: systemimage vendorimage userdataimage $(QEMU_DTB_IMG)
	$(DEVICE_PATH)/build/scripts/mkimg_android.sh \
	$(HOST_OUT) \
	$(PRODUCT_OUT)

droidcore: androidimage

endif
