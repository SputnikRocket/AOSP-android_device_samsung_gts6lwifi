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

LOCAL_PATH := $(call my-dir)

ifeq ($(TARGET_DEVICE),gts6lwifi)

$(eval $(call declare-1p-copy-files,device/samsung/gts6lwifi,.rc))
$(eval $(call declare-1p-copy-files,device/samsung/gts6lwifi,.xml))
$(eval $(call declare-1p-copy-files,device/samsung/gts6lwifi,fstab.gts6lwifi))

# Mesa (freedreno and turnip) from the Linaro vendor package, the build that
# db845c ships. Its own Android.mk only defines these modules for db845c and
# sm8x50 (by TARGET_DEVICE), so define them here, from the same files.
# Building Mesa from external/mesa3d instead: TARGET_BUILD_MESA := true.
ifneq ($(TARGET_BUILD_MESA),true)

GTS6LWIFI_MESA_DIR := $(LINARO_VENDOR_PATH)shared/$(EXPECTED_LINARO_VENDOR_VERSION)/mesa_prebuilt

ifeq ($(wildcard $(GTS6LWIFI_MESA_DIR)/LICENSE),)
$(warning Missing $(GTS6LWIFI_MESA_DIR): run ./device/linaro/dragonboard/fetch-vendor-package.sh)
else

# $(1): module name, $(2): directory under lib64/ (empty for lib64/ itself),
# $(3): the libraries it links against (its DT_NEEDED, less libc, libm, libdl
# and libc++, which the build adds itself). Listing them makes the build
# install their vendor variants: nothing else on this device's vendor
# partition needs libhardware or libui, and without them SurfaceFlinger
# cannot load libEGL_mesa.
define gts6lwifi-mesa-prebuilt
include $$(CLEAR_VARS)
LOCAL_MODULE := $(1)
LOCAL_MODULE_RELATIVE_PATH := $(2)
LOCAL_LICENSE_KINDS := SPDX-license-identifier-MIT
LOCAL_LICENSE_CONDITIONS := notice
LOCAL_NOTICE_FILE := $(GTS6LWIFI_MESA_DIR)/LICENSE
LOCAL_MODULE_CLASS := SHARED_LIBRARIES
LOCAL_MODULE_SUFFIX := .so
LOCAL_VENDOR_MODULE := true
LOCAL_STRIP_MODULE := false
LOCAL_CHECK_ELF_FILES := false
LOCAL_MULTILIB := 64
LOCAL_SHARED_LIBRARIES := $(3)
LOCAL_SRC_FILES := ../../../$(GTS6LWIFI_MESA_DIR)/lib64/$(if $(2),$(2)/)$(1).so
include $$(BUILD_PREBUILT)
endef

GTS6LWIFI_MESA_GALLIUM_LIBS := libdrm liblog libcutils libz libsync
GTS6LWIFI_MESA_WINSYS_LIBS := libdrm liblog libcutils libnativewindow libsync libhardware libui

$(eval $(call gts6lwifi-mesa-prebuilt,libEGL_mesa,egl,$(GTS6LWIFI_MESA_WINSYS_LIBS) libgallium_dri))
$(eval $(call gts6lwifi-mesa-prebuilt,libGLESv1_CM_mesa,egl,libgallium_dri))
$(eval $(call gts6lwifi-mesa-prebuilt,libGLESv2_mesa,egl,libgallium_dri))
$(eval $(call gts6lwifi-mesa-prebuilt,libgallium_dri,,$(GTS6LWIFI_MESA_GALLIUM_LIBS)))
$(eval $(call gts6lwifi-mesa-prebuilt,vulkan.freedreno,hw,$(GTS6LWIFI_MESA_WINSYS_LIBS) libz))

endif
endif

endif
