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

# Much of this follows device/linaro/dragonboard (db845c), the AOSP board
# that runs android-mainline kernels with mainline graphics, and reuses its
# graphics configuration and Qualcomm userspace helpers.

LOCAL_PATH := device/samsung/gts6lwifi

TARGET_HARDWARE := gts6lwifi

# The kernel (Image with the DTB appended, as Samsung's bootloader wants it)
# and dtbo.img come from the android-mainline port's CI:
#   https://github.com/SputnikRocket/linux-android-gts6lwifi
TARGET_KERNEL_DIR ?= device/samsung/gts6lwifi-kernel
ifeq ($(wildcard $(TARGET_KERNEL_DIR)/Image-dtb),)
  $(warning Missing $(TARGET_KERNEL_DIR)/Image-dtb: see device/samsung/gts6lwifi/README.md)
endif

$(call inherit-product, $(SRC_TARGET_DIR)/product/updatable_apex.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/emulated_storage.mk)
$(call inherit-product, frameworks/native/build/tablet-10in-xhdpi-2048-dalvik-heap.mk)

# Launched with Android 9 and non-dynamic partitions; keep the stock layout
PRODUCT_SHIPPING_API_LEVEL := 28
PRODUCT_USE_DYNAMIC_PARTITIONS := false
# Size system.img and vendor.img to their contents
PRODUCT_USE_DYNAMIC_PARTITION_SIZE := true
PRODUCT_OTA_ENFORCE_VINTF_KERNEL_REQUIREMENTS := false

PRODUCT_CHARACTERISTICS := tablet
PRODUCT_AAPT_PREF_CONFIG := xhdpi
DEVICE_PACKAGE_OVERLAYS := $(LOCAL_PATH)/overlay

PRODUCT_SOONG_NAMESPACES += \
    device/samsung/gts6lwifi \
    device/linaro/dragonboard

# Linaro vendor package (Mesa and linux-firmware prebuilts):
#   ./device/linaro/dragonboard/fetch-vendor-package.sh
include device/linaro/dragonboard/vendor-package-ver.mk
ifeq ($(wildcard $(LINARO_VENDOR_PATH)shared/$(EXPECTED_LINARO_VENDOR_VERSION)),)
  $(warning Missing the Linaro vendor package: run ./device/linaro/dragonboard/fetch-vendor-package.sh)
endif
PRODUCT_SOONG_NAMESPACES += \
    vendor/linaro/shared/$(EXPECTED_LINARO_VENDOR_VERSION)/linux-firmware

#
# Kernel, boot and storage
#
PRODUCT_COPY_FILES += \
    $(TARGET_KERNEL_DIR)/Image-dtb:kernel \
    $(LOCAL_PATH)/fstab.gts6lwifi:$(TARGET_COPY_OUT_RAMDISK)/first_stage_ramdisk/fstab.$(TARGET_HARDWARE) \
    $(LOCAL_PATH)/fstab.gts6lwifi:$(TARGET_COPY_OUT_VENDOR)/etc/fstab.$(TARGET_HARDWARE) \
    $(LOCAL_PATH)/init.gts6lwifi.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.$(TARGET_HARDWARE).rc \
    $(LOCAL_PATH)/init.gts6lwifi.usb.rc:$(TARGET_COPY_OUT_VENDOR)/etc/init/hw/init.$(TARGET_HARDWARE).usb.rc \
    $(LOCAL_PATH)/ueventd.gts6lwifi.rc:$(TARGET_COPY_OUT_VENDOR)/etc/ueventd.rc

PRODUCT_VENDOR_PROPERTIES += \
    persist.sys.zram_enabled=1

# Metadata encryption: the kernel's dm-default-key (2.x) takes the version 2
# table format; vold defaults to the legacy one on devices that launched with
# Android 10 or earlier, and the kernel then refuses the table.
PRODUCT_VENDOR_PROPERTIES += \
    ro.crypto.dm_default_key.options_format.version=2

#
# Graphics: Mesa freedreno (GL) and turnip (Vulkan) on the MSM DRM driver,
# drm_hwcomposer and minigbm, as on db845c
#
$(call inherit-product, device/linaro/dragonboard/shared/graphics/drm_hwcomposer/device.mk)
$(call inherit-product, device/linaro/dragonboard/shared/graphics/minigbm_msm/device.mk)

PRODUCT_PACKAGES += \
    libEGL_mesa \
    libGLESv1_CM_mesa \
    libGLESv2_mesa \
    libgallium_dri \
    vulkan.freedreno

# Adreno 640: SQE microcode (shared with the A630) and GMU firmware. The
# zap shader is the device's own, from the firmware partition.
PRODUCT_PACKAGES += \
    a630_sqe.fw \
    a640_gmu.bin \
    gts6lwifi_apnhlos_firmware

PRODUCT_VENDOR_PROPERTIES += \
    ro.hardware.egl=mesa \
    ro.hardware.vulkan=freedreno \
    ro.opengles.version=196608 \
    debug.hwui.renderer=skiagl

# The MSM display driver takes over from simpledrm (the bootloader's splash)
# but keeps DRM minor 1: there is no card0 for drm_hwcomposer to start from.
PRODUCT_VENDOR_PROPERTIES += \
    vendor.hwc.drm.device=/dev/dri/card1

# 2560x1600 on 10.5": 287 dpi
PRODUCT_VENDOR_PROPERTIES += \
    ro.sf.lcd_density=320

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.opengles.aep.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.opengles.aep.xml \
    frameworks/native/data/etc/android.software.opengles.deqp.level-2022-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.opengles.deqp.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.compute-0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.compute.xml \
    frameworks/native/data/etc/android.hardware.vulkan.level-1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.level.xml \
    frameworks/native/data/etc/android.hardware.vulkan.version-1_1.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.vulkan.version.xml \
    frameworks/native/data/etc/android.software.vulkan.deqp.level-2021-03-01.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.vulkan.deqp.level.xml

TARGET_USES_VULKAN := true

#
# Device features
#
PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/tablet_core_hardware.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/tablet_core_hardware.xml \
    frameworks/native/data/etc/android.hardware.touchscreen.multitouch.jazzhand.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.touchscreen.multitouch.jazzhand.xml \
    frameworks/native/data/etc/android.hardware.usb.accessory.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.usb.accessory.xml \
    frameworks/native/data/etc/android.software.app_widgets.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.app_widgets.xml \
    frameworks/native/data/etc/android.software.backup.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.backup.xml \
    frameworks/native/data/etc/android.software.device_admin.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.device_admin.xml \
    frameworks/native/data/etc/android.software.print.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.print.xml \
    frameworks/native/data/etc/android.software.voice_recognizers.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.software.voice_recognizers.xml

#
# HALs. There is no TEE support (qseecom) in the mainline kernel, so
# KeyMint and Gatekeeper are the software implementations, as on db845c.
#
PRODUCT_PACKAGES += \
    com.android.hardware.keymint.rust_nonsecure \
    com.android.hardware.gatekeeper.nonsecure

PRODUCT_COPY_FILES += \
    frameworks/native/data/etc/android.hardware.keystore.app_attest_key.xml:$(TARGET_COPY_OUT_VENDOR)/etc/permissions/android.hardware.keystore.app_attest_key.xml

# No fuel gauge driver yet: the Cuttlefish health HAL reports a full battery
PRODUCT_PACKAGES += \
    com.google.cf.health

PRODUCT_PACKAGES += \
    android.hardware.power-service.example \
    android.hardware.power.stats-service.example \
    com.android.hardware.thermal

PRODUCT_PACKAGES += \
    suspend_blocker

PRODUCT_PACKAGES += \
    android.hardware.drm-service.clearkey

# Audio and media: the AIDL default audio HAL and the software codecs, with
# db845c's (board independent) configuration. There is no audio driver yet.
PRODUCT_PACKAGES += \
    com.android.hardware.audio \
    audio.bluetooth.default \
    audio.r_submix.default \
    audio.usb.default

USE_XML_AUDIO_POLICY_CONF := 1
PRODUCT_COPY_FILES += \
    device/linaro/dragonboard/etc/audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_configuration.xml \
    hardware/interfaces/audio/aidl/default/audio_effects_config.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects_config.xml \
    frameworks/av/services/audiopolicy/config/bluetooth_audio_policy_configuration_7_0.xml:$(TARGET_COPY_OUT_VENDOR)/etc/bluetooth_audio_policy_configuration_7_0.xml \
    frameworks/av/services/audiopolicy/config/r_submix_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/r_submix_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/usb_audio_policy_configuration.xml:$(TARGET_COPY_OUT_VENDOR)/etc/usb_audio_policy_configuration.xml \
    frameworks/av/services/audiopolicy/config/default_volume_tables.xml:$(TARGET_COPY_OUT_VENDOR)/etc/default_volume_tables.xml \
    frameworks/av/services/audiopolicy/config/audio_policy_volumes.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_policy_volumes.xml

PRODUCT_COPY_FILES += \
    device/linaro/dragonboard/etc/media_codecs.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs.xml \
    frameworks/av/media/libeffects/data/audio_effects.xml:$(TARGET_COPY_OUT_VENDOR)/etc/audio_effects.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_video.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_video.xml \
    frameworks/av/media/libstagefright/data/media_codecs_google_audio.xml:$(TARGET_COPY_OUT_VENDOR)/etc/media_codecs_google_audio.xml

PRODUCT_VENDOR_PROPERTIES += \
    media.c2.hal.selection=aidl \
    debug.stagefright.c2inputsurface=-1

#
# Remote processors: the kernel has the protection domain mapper and the
# QRTR name service built in; the modem (which also runs the WLAN firmware)
# needs rmtfs for its file system and tqftpserv for its configuration.
#
PRODUCT_PACKAGES += \
    rmtfs \
    tqftpserv

DEVICE_MANIFEST_FILE := $(LOCAL_PATH)/manifest.xml

# adb asks to trust a computer on the screen, which may not work yet. Keys
# put in $(GTS6LWIFI_LOCAL_DIR)/adb_keys (adbkey.pub files, one per line;
# kept out of this repository) are trusted from the first boot.
GTS6LWIFI_LOCAL_DIR ?= device/samsung/gts6lwifi-local
ifneq ($(wildcard $(GTS6LWIFI_LOCAL_DIR)/adb_keys),)
  PRODUCT_ADB_KEYS := $(GTS6LWIFI_LOCAL_DIR)/adb_keys
endif

PRODUCT_HOST_PACKAGES += \
    mkbootimg
