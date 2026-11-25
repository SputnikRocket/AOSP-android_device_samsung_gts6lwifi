#
# Copyright (C) 2026 The Android Open Source Project
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Architecture: Qualcomm SM8150 (Snapdragon 855), Kryo 485
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-2a-dotprod
TARGET_CPU_VARIANT := cortex-a76
TARGET_CPU_ABI := arm64-v8a

TARGET_BOOTLOADER_BOARD_NAME := gts6lwifi
TARGET_BOARD_PLATFORM := sm8150
TARGET_NO_BOOTLOADER := true
TARGET_NO_RECOVERY := true

#
# Boot image. Samsung's bootloader (Qualcomm ABL) takes a header v1 boot
# image with the DTB appended to the kernel (Image-dtb) and the stock
# offsets, and adds its own command line (serial number, boot device,
# verified boot state) after ours.
#
TARGET_NO_KERNEL := false
TARGET_KERNEL_DIR ?= device/samsung/gts6lwifi-kernel
BOARD_BOOT_HEADER_VERSION := 1
BOARD_KERNEL_PAGESIZE := 4096
BOARD_KERNEL_BASE := 0x00000000
BOARD_MKBOOTIMG_ARGS := \
    --header_version $(BOARD_BOOT_HEADER_VERSION) \
    --kernel_offset 0x00008000 \
    --ramdisk_offset 0x00000000 \
    --second_offset 0x00000000 \
    --tags_offset 0x01e00000 \
    --board SRPSD11A005
BOARD_PREBUILT_DTBOIMAGE := $(TARGET_KERNEL_DIR)/dtbo.img
BOARD_BOOTIMAGE_PARTITION_SIZE := 67108864
BOARD_DTBOIMG_PARTITION_SIZE := 8388608

BOARD_KERNEL_CMDLINE := \
    androidboot.hardware=gts6lwifi \
    androidboot.boot_devices=soc/1d84000.ufshc \
    androidboot.usbcontroller=a600000.usb \
    androidboot.memcg=1 \
    androidboot.verifiedbootstate=orange \
    firmware_class.path=/vendor/firmware \
    printk.devkmsg=on \
    deferred_probe_timeout=30 \
    clk_ignore_unused \
    pd_ignore_unused \
    console=tty0 \
    fbcon=font:TER16x32
# Samsung keeps a RAM log the bootloader copies to the debug partition
BOARD_KERNEL_CMDLINE += sec_log=0x200000@0xC1600000
# Bring-up: SELinux denials are logged, not enforced (userdebug and eng only)
BOARD_KERNEL_CMDLINE += androidboot.selinux=permissive

# The stock vbmeta has to be replaced with one that disables verification
BOARD_AVB_ENABLE := false

#
# Partitions: the stock (non-dynamic) layout. system holds system_ext and
# product; images are sized to their contents and fit the stock partitions.
# cache (unused by AOSP) is the metadata partition.
#
BOARD_FLASH_BLOCK_SIZE := 4096
BOARD_SYSTEMIMAGE_FILE_SYSTEM_TYPE := erofs
BOARD_VENDORIMAGE_FILE_SYSTEM_TYPE := erofs
TARGET_COPY_OUT_VENDOR := vendor
BOARD_USES_METADATA_PARTITION := true
TARGET_USERIMAGES_USE_F2FS := true
TARGET_USERIMAGES_USE_EXT4 := true
BOARD_F2FS_BLOCKSIZE := 4096
# Raw images, to write them with dd or TWRP's "Install Image"
TARGET_USERIMAGES_SPARSE_EROFS_DISABLED := true
TARGET_USERIMAGES_SPARSE_EXT_DISABLED := true

#
# Graphics
#
BOARD_USES_DRM_HWCOMPOSER := true
TARGET_USES_HWC2 := true
# Mesa prebuilts from the Linaro vendor package (see Android.mk)
BOARD_USE_CUSTOMIZED_MESA := true

BOARD_SEPOLICY_DIRS += \
    device/linaro/dragonboard/sepolicy \
    device/linaro/dragonboard/shared/graphics/minigbm_msm/sepolicy \
    device/samsung/gts6lwifi/sepolicy
