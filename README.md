# Samsung Galaxy Tab S6 Wi-Fi (SM-T860, gts6lwifi): AOSP device configuration

AOSP device configuration (`device/samsung/gts6lwifi`) for Android 17
(`android17-release`). It runs on the
[android-mainline kernel port](https://github.com/SputnikRocket/linux-android-gts6lwifi)
with mainline graphics: Mesa freedreno (GL) and turnip (Vulkan), drm_hwcomposer
and minigbm. That is how AOSP's own Qualcomm board, db845c
(`device/linaro/dragonboard`), runs android-mainline, and this tree reuses
its graphics configuration and its Qualcomm userspace helpers.

**Status: bring-up.** It builds, and the tablet boots to the lock screen,
with SurfaceFlinger rendering through Mesa. SELinux is permissive
(`androidboot.selinux=permissive`) and still logs many denials. During
bring-up the tablet sometimes restarted by itself after a few minutes; that
has not been looked into yet.

| Area | State |
| --- | --- |
| Boot, storage (UFS, microSD) | Kernel side works (tested with the stock Android 12 system and vendor) |
| USB (adb) | Works; see [Building](#building) for adb without the screen |
| Display (AMSA05RB06, dual DSI, command mode) | Works, through drm_hwcomposer, which also sets the brightness (the panel's `/sys/class/backlight` device) |
| GPU (Adreno 640) | Works for SurfaceFlinger: Mesa from the Linaro vendor package; the zap shader comes from the device's firmware partition |
| Touchscreen | Works, from kernel run 43 (earlier kernels report it rotated) |
| KeyMint, Gatekeeper | Software implementations: the mainline kernel has no Qualcomm TEE (qseecom) driver |
| Wi-Fi (WCN3998, ath10k), hotspot, Wi-Fi Direct | Being brought up: wpa_supplicant and hostapd over nl80211, no vendor Wi-Fi HAL (as on db845c). The WLAN firmware runs on the modem DSP, whose firmware isn't reachable yet |
| Bluetooth (WCN3998, hci_qca) | Being brought up: the default Bluetooth HAL over the kernel's HCI user channel, an address set at boot; A2DP through the audio HAL's Bluetooth module |
| Audio, sensors, cameras, battery | Not yet (the health HAL reports a full battery) |

## Partitions

The device launched with Android 9 and has no `super` partition. This tree
keeps the stock layout:

| Partition | Contents |
| --- | --- |
| `boot` | Kernel (`Image-dtb`: the DTB appended, as the bootloader wants it) and AOSP's first stage ramdisk, boot image header v1 |
| `dtbo` | A placeholder overlay from the kernel build (the bootloader requires a valid one) |
| `system` | erofs: system, with system_ext and product inside |
| `vendor` | erofs |
| `cache` | `/metadata` (ext4, formatted on first boot) |
| `userdata` | `/data` (f2fs or ext4) |
| `apnhlos` | The stock firmware partition, mounted read-only at `/mnt/vendor/apnhlos` |
| `vbmeta` | Must be one with verification disabled |

`system.img` and `vendor.img` are sized to their contents and written raw,
not sparse. The stock partitions have room: `system` is 6.1 GiB and `vendor`
1.3 GiB.

## Building

You need a Linux machine that can build AOSP: about 400 GB of free disk space
and 64 GB of RAM.

1. Get the Android 17 sources, with this repository as
   `device/samsung/gts6lwifi` (an example
   [local manifest](local_manifests/gts6lwifi.xml)):

   ```bash
   mkdir aosp && cd aosp
   repo init -u https://android.googlesource.com/platform/manifest -b android17-release
   mkdir -p .repo/local_manifests
   curl -o .repo/local_manifests/gts6lwifi.xml https://raw.githubusercontent.com/SputnikRocket/AOSP-android_device_samsung_gts6lwifi/main/local_manifests/gts6lwifi.xml
   repo sync -c -j8
   ```

2. Get the Linaro vendor package, which holds the Mesa build and the
   linux-firmware files db845c uses:

   ```bash
   ./device/linaro/dragonboard/fetch-vendor-package.sh
   ```

3. Get the kernel. From the
   [kernel's Actions](https://github.com/SputnikRocket/linux-android-gts6lwifi/actions),
   take a build of the plain variant (no `usbcon`, `reboot` or `drmdebug`
   suffix: the USB console variant takes the USB port for itself), run 42
   or later: earlier kernels leave the panel dark. Put its
   `Image-dtb` (from the `gts6lwifi-mainline-kernel-N` artifact) and
   `dtbo.img` (from `gts6lwifi-mainline-boot-img-N`) in
   `device/samsung/gts6lwifi-kernel/`. To use another directory, set
   `TARGET_KERNEL_DIR`.

4. Copy Samsung's Wi-Fi and Bluetooth firmware from the tablet's own stock
   vendor partition (it can't be shared, so it isn't in this repository):
   with an image of it (from TWRP, or `adb shell su -c 'dd
   if=/dev/block/by-name/vendor' > stock-vendor.img` while the stock system
   still runs), or a directory with its contents,

   ```bash
   ./device/samsung/gts6lwifi/extract-files.sh stock-vendor.img
   ```

   It writes `vendor/samsung/gts6lwifi` (see
   [proprietary-files.txt](proprietary-files.txt)). Without it the build
   warns and has no Wi-Fi.

5. Let adb in without the screen: adb asks to trust a computer on the
   tablet's screen, which may not work yet. Put the `adbkey.pub` of each
   computer you will use (on Windows `%UserProfile%\.android\adbkey.pub`,
   elsewhere `~/.android/adbkey.pub`) into
   `device/samsung/gts6lwifi-local/adb_keys`, one per line; the build trusts
   them (`PRODUCT_ADB_KEYS`). That directory is not part of this repository.

6. Build:

   ```bash
   source build/envsetup.sh
   lunch gts6lwifi-cp2a-userdebug
   m
   ```

   `cp2a` is the Android 17 release configuration. With `trunk_staging`, the
   same sources build a development platform (`PLATFORM_VERSION=Baklava`).

   Soong's analysis of the whole tree alone needs about 32 GB of memory; with
   less, it gets killed (`soong bootstrap failed with: exit status 143`). On
   WSL2, which by default gets half of the PC's memory, raise the limit in
   `%UserProfile%\.wslconfig` (for example `memory=48GB` and `swap=32GB`
   under `[wsl2]`), then run `wsl --shutdown` and start the build again.

   The images are in `out/target/product/gts6lwifi/`: `boot.img`,
   `dtbo.img`, `system.img` and `vendor.img`.

## Installing

From TWRP, with a vbmeta that disables verification already flashed:

1. Samsung's own boot images end with a `SEANDROIDENFORCE` trailer, which
   the kernel's CI adds too; AOSP's `mkbootimg` does not. Add it to be safe
   (the bootloader ignores what follows the image, apart from this):

   ```bash
   printf SEANDROIDENFORCE >> out/target/product/gts6lwifi/boot.img
   ```

   Then copy the images to the microSD card (TWRP's `/tmp` is in RAM, too
   small for `system.img`):

   ```bash
   adb shell mkdir -p /external_sd/aosp
   ```

   ```bash
   adb push boot.img dtbo.img system.img vendor.img /external_sd/aosp/
   ```

2. Write them:

   ```bash
   adb shell 'cd /external_sd/aosp && for p in boot dtbo system vendor; do dd if=$p.img of=/dev/block/by-name/$p bs=4M || exit 1; done; sync'
   ```

3. Blank `userdata` and `cache` (the metadata partition). The stock data is
   encrypted with keys AOSP does not have, and with metadata encryption
   Android has to format `/data` itself on the first boot; it does so only
   when it finds no file system there. TWRP's Format Data is not enough: it
   leaves an ext4 that Android then cannot open. If `umount /data` fails,
   untick Data under Mount first.

   ```bash
   adb shell 'umount /data; umount /cache; for p in userdata cache; do dd if=/dev/zero of=/dev/block/by-name/$p bs=1M count=64 || exit 1; done; sync'
   ```

4. Reboot. The first boot takes longer: it formats `/metadata` and `/data`.
   To go back to stock, flash the stock firmware with Odin.

## Firmware

| File | From |
| --- | --- |
| `qcom/a630_sqe.fw` | linux-firmware, in the Linaro vendor package |
| `qcom/a640_gmu.bin` | linux-firmware, in [`firmware/`](firmware) (with its license) |
| `qcom/sm8150/samsung/gts6lwifi/*` | The device's own firmware partition: a link to `/mnt/vendor/apnhlos/image` |
| `ath10k/WCN3990/hw1.0/firmware-5.bin` | linux-firmware, in the Linaro vendor package: ath10k's description of the WLAN firmware |
| `ath10k/WCN3990/hw1.0/board.bin`, `qcom/sm8150/samsung/gts6lwifi-modem/wlanmdsp.mbn`, `qca/crbtfw21.tlv`, `qca/crnv21.bin` | Samsung's, from the stock vendor partition (`extract-files.sh`): the WLAN board data, the WLAN firmware the modem runs, the Bluetooth firmware and its NVM |
| `regulatory.db` | [wireless-regdb](https://git.kernel.org/pub/scm/linux/kernel/git/wens/wireless-regdb.git), in [`firmware/`](firmware) (with its license): the regulatory database for cfg80211 |

The kernel loads all of them from `firmware_class.path=/vendor/firmware`. The
remote processors start before `/mnt/vendor/apnhlos` is mounted, so
`init.gts6lwifi.rc` starts them again once it is.

The GPU zap shader is signed for the device, so it comes from the device
too: `a640_zap.mdt` and `a640_zap.b00` to `.b02` are in the firmware
partition's `image/` directory, next to the remote processor firmware.
