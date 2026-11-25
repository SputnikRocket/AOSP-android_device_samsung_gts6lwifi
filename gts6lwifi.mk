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

# Samsung Galaxy Tab S6 Wi-Fi (SM-T860): AOSP on the android-mainline kernel,
# with Mesa freedreno, drm_hwcomposer and minigbm for graphics.

# The shipping API level (28) would bring in the HIDL MediaCas service, which
# the device's FCM level (202504) does not allow any more; the AIDL one
# (com.android.hardware.cas) is there. Read while base_vendor.mk is
# inherited, so it has to be set before that.
TARGET_REQUIRES_HIDL_CAS_HAL := false

$(call inherit-product, $(SRC_TARGET_DIR)/product/core_64_bit_only.mk)
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base.mk)
$(call inherit-product, device/samsung/gts6lwifi/device.mk)

PRODUCT_NAME := gts6lwifi
PRODUCT_DEVICE := gts6lwifi
PRODUCT_BRAND := samsung
PRODUCT_MANUFACTURER := samsung
PRODUCT_MODEL := SM-T860
