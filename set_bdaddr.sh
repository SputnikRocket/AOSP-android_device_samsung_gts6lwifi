#!/vendor/bin/sh
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

# The WCN3998 has no Bluetooth address of its own, so the kernel keeps it
# unconfigured until one is set. Give it a random static address (the two
# top bits set), the same at every boot: from a hash of the serial number,
# which Samsung's serials (letters and digits) can't be used as directly, as
# db845c's set_bdaddr.sh does with its hexadecimal ones.

serial=`/vendor/bin/grep -o 'androidboot\.serialno=[^ ]*' /proc/cmdline |
	/vendor/bin/cut -d= -f2`
[ -n "${serial}" ] || exit 1

hash=`echo -n "gts6lwifi-bt:${serial}" | /vendor/bin/md5sum | /vendor/bin/cut -c1-10`
addr=`echo "c0${hash}" | /vendor/bin/sed 's/\(..\)/\1:/g; s/:$//'`

/vendor/bin/hw/bdaddr "${addr}"
