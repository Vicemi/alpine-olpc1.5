#!/bin/sh
# Build the Alpine x86 root filesystem for the XO-1.5 (runs inside the i386/alpine image).
# Needs /output/kernel from kernel/build-kernel.sh. Output: /output/rootfs
set -eu

BRANCH="${ALPINE_BRANCH:-v3.24}"
MIRROR="${MIRROR:-https://dl-cdn.alpinelinux.org/alpine}"
R=/output/rootfs
SRC="$(cd "$(dirname "$0")/.." && pwd)"

[ -f /output/kernel/vmlinuz ] || { echo "!! run the kernel build first"; exit 1; }

PKGS="
alpine-base openrc busybox-openrc agetty doas nano htop tzdata
e2fsprogs e2fsprogs-extra dosfstools blkid sfdisk cloud-utils-growpart
eudev udev-init-scripts udev-init-scripts-openrc dbus dbus-openrc
networkmanager networkmanager-openrc networkmanager-wifi networkmanager-cli wpa_supplicant network-manager-applet
linux-firmware-libertas zstd chrony zram-init zram-init-openrc alsa-utils
xorg-server xf86-video-fbdev xf86-input-libinput xinit xrdb setxkbmap xset
font-dejavu adwaita-icon-theme icewm pcmanfm lxterminal
firefox-esr
"

rm -rf "$R"; mkdir -p "$R/etc/apk"
cp -r /etc/apk/keys "$R/etc/apk/"
printf '%s\n' "$MIRROR/$BRANCH/main" "$MIRROR/$BRANCH/community" > "$R/etc/apk/repositories"
# shellcheck disable=SC2086
apk --root "$R" --initdb --arch x86 --no-cache --update-cache add $PKGS

# Kernel modules from our build
cp -a /output/kernel/modules/lib/modules "$R/lib/"

# Static config files (inittab, X, NetworkManager, IceWM, Firefox prefs, first-boot grow...)
cp -r "$SRC/overlay/." "$R/"   # no -a: files must end up owned by root
mkdir -p "$R/boot"   # mount point for the FAT boot partition

# zram: only the 512 MB swap device (the default also makes a 2 GB zram /tmp); lz4 is cheapest on a C7
sed -i 's/^num_devices=.*/num_devices=1/; s/^algo0=.*/algo0=lz4/' "$R/etc/conf.d/zram-init"

run() { chroot "$R" /bin/sh -c "$*"; }
run "depmod -a $(ls "$R/lib/modules")"
run /etc/local.d/05-firmware-unzstd.start

for s in devfs dmesg udev udev-trigger udev-settle;                  do run rc-update add $s sysinit; done
for s in hwclock modules sysctl hostname bootmisc syslog seedrng \
         fsck root localmount udev-postmount;                        do run rc-update add $s boot; done
for s in dbus networkmanager chronyd zram-init local;                do run rc-update add $s default; done
for s in mount-ro killprocs savecache;                               do run rc-update add $s shutdown; done

# User olpc (autologin on tty1 -> startx). Default passwords: olpc / olpc (change them!)
run "adduser -D -s /bin/ash olpc"
for g in wheel audio video input netdev plugdev; do run "addgroup olpc $g" 2>/dev/null || true; done
run "echo 'olpc:olpc' | chpasswd && echo 'root:olpc' | chpasswd"
run "chown -R olpc:olpc /home/olpc"
ln -sf /usr/share/zoneinfo/America/Montevideo "$R/etc/localtime"
echo America/Montevideo > "$R/etc/timezone"

# Firefox low-RAM prefs live next to the binary; fail loudly if the path changed
FFDIR="$(cd "$R" && ls -d usr/lib/firefox* | head -1)"
[ -n "$FFDIR" ] || { echo "!! firefox not found"; exit 1; }
mkdir -p "$R/$FFDIR/defaults/pref"
cp "$SRC/config/firefox-xo.js" "$R/$FFDIR/defaults/pref/"

rm -rf "$R/var/cache/apk/"*
echo ">> rootfs: $(du -sh "$R" | cut -f1)"
