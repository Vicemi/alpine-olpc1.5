#!/usr/bin/env bash
# Build a non-PAE Linux 5.15 LTS kernel for the XO-1.5 (runs inside kernel/Dockerfile).
# Output: /output/kernel/vmlinuz, /output/kernel/modules/lib/modules/<ver>, /output/kernel/config
set -euo pipefail

KVER="${KVER:-5.15.224}"
ALPINE_BRANCH="${ALPINE_BRANCH:-3.24}"
SRC=/output/kernelsrc
OUT=/output/kernel
HERE="$(dirname "$0")"

mkdir -p "$SRC" "$OUT"
cd "$SRC"
if [ ! -d "linux-$KVER" ]; then
    curl -fL "https://cdn.kernel.org/pub/linux/kernel/v5.x/linux-$KVER.tar.xz" | tar xJ
fi
cd "linux-$KVER"

# Base: the FULL config shipped in Alpine's x86 linux-lts package (broad driver coverage, non-PAE).
# Not aports' lts.x86.config: that one is minimized against 6.x defaults, and options that are
# default-y there but default-n in 5.15 (UNIX, INET, ...) would silently vanish.
REPO="https://dl-cdn.alpinelinux.org/alpine/v$ALPINE_BRANCH/main/x86"
curl -fsSL "$REPO/APKINDEX.tar.gz" -o /tmp/APKINDEX.tar.gz
LTSVER="$(tar xzOf /tmp/APKINDEX.tar.gz APKINDEX | awk '/^P:linux-lts$/{f=1} f&&/^V:/{print substr($0,3); f=0}')"  # no early exit: SIGPIPE + pipefail
curl -fsSL "$REPO/linux-lts-$LTSVER.apk" -o /tmp/linux-lts.apk
tar xzf /tmp/linux-lts.apk --ignore-zeros --wildcards -O 'boot/config-*' > .config
grep -q '^CONFIG_UNIX=y' .config || { echo "!! could not get linux-lts $LTSVER config"; exit 1; }
# Alpine signs with its builder's key; generate our own per build instead
scripts/config --set-str MODULE_SIG_KEY certs/signing_key.pem --set-str SYSTEM_TRUSTED_KEYS ""
make ARCH=i386 olddefconfig >/dev/null
while IFS='=' read -r key val; do
    case "$key" in ''|\#*) continue ;; esac
    opt="${key#CONFIG_}"
    case "$val" in
        y) scripts/config --enable "$opt" ;;
        m) scripts/config --module "$opt" ;;
        n) scripts/config --disable "$opt" ;;
    esac
done < "$HERE/xo15.config"
make ARCH=i386 olddefconfig >/dev/null

# Hard check: every override must survive olddefconfig (dependencies can silently drop them).
fail=0
while IFS='=' read -r key val; do
    case "$key" in ''|\#*) continue ;; esac
    if [ "$val" = n ]; then
        grep -q "^$key=" .config && { echo "!! $key should be off"; fail=1; }
    else
        # =m is satisfied by =y too
        grep -qE "^$key=($val|y)$" .config ||{ echo "!! $key=$val missing (got: $(grep "^$key=\|$key is not set" .config))"; fail=1; }
    fi
done < "$HERE/xo15.config"
[ "$fail" = 0 ] || exit 1

make ARCH=i386 -j"$(nproc)" bzImage modules
rm -rf "$OUT/modules"
make ARCH=i386 INSTALL_MOD_PATH="$OUT/modules" INSTALL_MOD_STRIP=1 modules_install
rm -f "$OUT"/modules/lib/modules/*/build "$OUT"/modules/lib/modules/*/source
cp arch/x86/boot/bzImage "$OUT/vmlinuz"
cp .config "$OUT/config"
echo ">> kernel $(make -s kernelrelease) -> $OUT ($(du -h "$OUT/vmlinuz" | cut -f1))"
