#!/bin/sh
# Assemble the SD/USB image from /output/kernel + /output/rootfs, without loop devices.
#   p1  FAT32 64 MiB : \vmlinuz  \boot\olpc.fth   (read by Open Firmware, mounted at /boot)
#   p2  ext4         : Alpine root (grown to the full card on first boot)
# Output: /output/alpine-xo15.img.xz
set -eu

SRC="$(cd "$(dirname "$0")/.." && pwd)"
O=/output
W=$O/imgwork
R=$O/rootfs
rm -rf "$W"; mkdir -p "$W"

PARTUUID="$(od -An -N4 -tx4 /dev/urandom | tr -d ' ')"

BOOT_MB=64
ROOT_MB=$(( $(du -sm "$R" | cut -f1) * 115 / 100 + 300 ))

# p1: FAT32 boot partition
mkfs.vfat -F 32 -n XOBOOT -C "$W/boot.img" $((BOOT_MB * 1024)) >/dev/null
sed "s/@PARTUUID@/$PARTUUID/" "$SRC/boot/olpc.fth" > "$W/olpc.fth"
mmd   -i "$W/boot.img" ::/boot
mcopy -i "$W/boot.img" /output/kernel/vmlinuz ::/vmlinuz
mcopy -i "$W/boot.img" "$W/olpc.fth" ::/boot/olpc.fth

# p2: ext4 root, filled straight from the directory
mkfs.ext4 -q -L xoroot -O ^orphan_file -d "$R" "$W/root.img" "${ROOT_MB}M"

# Disk: MBR with our disk id (=> PARTUUID), p1 active
IMG=$O/alpine-xo15.img
TOTAL_MB=$((1 + BOOT_MB + ROOT_MB))
rm -f "$IMG" "$IMG.xz"; truncate -s "${TOTAL_MB}M" "$IMG"
sfdisk -q "$IMG" <<EOF
label: dos
label-id: 0x$PARTUUID
start=2048, size=$((BOOT_MB * 2048)), type=c, bootable
size=$((ROOT_MB * 2048)), type=83
EOF
dd if="$W/boot.img" of="$IMG" bs=1M seek=1 conv=notrunc status=none
dd if="$W/root.img" of="$IMG" bs=1M seek=$((1 + BOOT_MB)) conv=notrunc status=none

xz -T0 -6 -k "$IMG"
( cd $O && sha256sum alpine-xo15.img.xz > alpine-xo15.img.xz.sha256 )
rm -rf "$W"
echo ">> $IMG (${TOTAL_MB} MiB)  PARTUUID=$PARTUUID"
ls -lh "$IMG.xz"
