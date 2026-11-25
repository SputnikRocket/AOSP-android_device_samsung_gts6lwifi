# SELinux policy

- `.` (this directory): the tablet's own labels and rules.
- `dragonboard/`: `device/linaro/dragonboard/sepolicy` (android17-release,
  57c0fe5), the policy for db845c's Qualcomm userspace (rmtfs, tqftpserv,
  pd-mapper, qrtr) and graphics, without `tinymix.te` and the
  `/system/bin/tinymix` label.
- `minigbm_msm/`: `device/linaro/dragonboard/shared/graphics/minigbm_msm/sepolicy`,
  without the label for `/system/lib*/libdrm.so`; `dragonboard/` labels the
  vendor copy.

What was left out fails AOSP's Treble labeling check, enforced from board
API level 202604: vendor policy must not use `coredomain` or label files on
the system partition. The device uses neither tinymix nor a system libdrm.
