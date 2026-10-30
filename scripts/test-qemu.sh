#!/bin/sh
# Smoke test of output/alpine-xo15.img in QEMU, along the XO's boot path: SDHCI card,
# root=PARTUUID, no initramfs. The XO-only drivers (viafb, DCON, libertas) are not exercised;
# X runs on QEMU's bochs display instead. Needs qemu-system-i386 and socat.
# Output: output/qemu.log (serial console), output/qemu-screen.ppm (screenshot at the end)
set -eu
cd "$(dirname "$0")/../output"
SECS="${1:-420}"

cp alpine-xo15.img test.img
truncate -s 4G test.img   # QEMU SD cards must be a power of 2; also exercises first-boot grow
PUUID="$(sfdisk -d test.img | sed -n 's/^label-id: 0x//p')"

qemu-system-i386 -cpu qemu32 -smp 2 -m 1024 -display none -vga none -device bochs-display \
    -kernel kernel/vmlinuz -append "root=PARTUUID=$PUUID-02 rootwait ro console=tty0 console=ttyS0" \
    -drive if=none,id=sd,file=test.img,format=raw -device sdhci-pci -device sd-card,drive=sd \
    -nic user,model=rtl8139 -serial file:qemu.log -monitor unix:qemu.sock,server,nowait &
QPID=$!
sleep "$SECS"
echo "screendump qemu-screen.ppm" | socat - UNIX-CONNECT:qemu.sock >/dev/null
sleep 2
kill "$QPID"
grep -aE 'ERROR|fail|panic' qemu.log || echo ">> no errors on the serial console"
