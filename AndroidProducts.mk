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

PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/gts6lwifi.mk

# cp2a is android17-release's release config (BUILD_ID CP2A.*). trunk_staging
# there builds a development platform (codename Baklava), not Android 17.
COMMON_LUNCH_CHOICES := \
    gts6lwifi-cp2a-userdebug \
    gts6lwifi-cp2a-eng
