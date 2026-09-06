ifneq ($(filter qemu%, $(TARGET_DEVICE)),)

DEVICE_PATH := device/generic/qemu
DTB_GEN_SCRIPT := $(DEVICE_PATH)/build/scripts/mkimg_dt.sh
MKDTIMG_TOOL := $(HOST_OUT_EXECUTABLES)/mkdtimg
DTC_TOOL := $(HOST_OUT_EXECUTABLES)/dtc
MCOPY_TOOL := $(HOST_OUT_EXECUTABLES)/mcopy
NEWFS_MSDOS_TOOL := $(HOST_OUT_EXECUTABLES)/newfs_msdos

QEMU_DTB_IMG := $(PRODUCT_OUT)/$(TARGET_DEVICE)_dtb.img
QEMU_DTS_SRC := $(DEVICE_PATH)/fdts/$(TARGET_DEVICE).dts

$(QEMU_DTB_IMG): $(QEMU_DTS_SRC) $(MKDTIMG_TOOL) $(DTC_TOOL) $(MCOPY_TOOL) $(NEWFS_MSDOS_TOOL)
	@echo "Generating DTB image for $(TARGET_DEVICE)..."
	$(DTB_GEN_SCRIPT) $(HOST_OUT) $(PRODUCT_OUT) $(TARGET_DEVICE)

$(INSTALLED_VENDOR_BOOTIMAGE_TARGET): $(QEMU_DTB_IMG)

MKIMG_ANDROID_HOST_TOOLS := $(addprefix $(HOST_OUT_EXECUTABLES)/, \
    sgdisk \
    mke2fs \
    mtools \
    mcopy \
    toybox \
    one-true-awk \
)

.PHONY: androidimage
androidimage: systemimage vendorimage userdataimage $(QEMU_DTB_IMG) $(MKIMG_ANDROID_HOST_TOOLS)
	$(DEVICE_PATH)/build/scripts/mkimg_android.sh \
	$(HOST_OUT) \
	$(PRODUCT_OUT)

droidcore: androidimage

endif
