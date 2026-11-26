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

# The remote processors tried to start, and failed, before their firmware
# partitions were mounted: start them now. Not the modem, though: rmtfs
# starts it (-s) once it serves the modem's file system, which the modem
# needs from its first moments. remoteproc numbers follow probe order, so go
# by name.

for r in /sys/class/remoteproc/remoteproc*; do
	name=`/vendor/bin/cat ${r}/name`
	state=`/vendor/bin/cat ${r}/state`
	[ "${name}" = modem ] && continue
	[ "${state}" = offline ] || continue
	echo start > ${r}/state
done
