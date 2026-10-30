# alpine-olpc1.5

Alpine Linux image for the OLPC XO-1.5 (VIA C7, Open Firmware). Docs are in Spanish; code comments in English.

## Commands
- `docker compose run --rm kernel` — build kernel 5.15 non-PAE into `output/kernel`
- `docker compose run --rm image` — build rootfs + `output/alpine-xo15.img.xz`

## Hard rules
- Kernel stays on 5.15 LTS: `FB_OLPC_DCON` is `BROKEN` from 5.19 on.
- No initramfs: anything needed to mount `/` must be `=y` in `kernel/xo15.config`.
- `boot/olpc.fth` must keep `unfreeze visible` (see docs/architecture.md).
- Files must use LF line endings (`.gitattributes`); CRLF silently breaks `xo15.config` parsing.

## Docs map
- docs/architecture.md — boot chain, partitions, kernel and desktop choices
- docs/building.md — build and "what file to touch"
- docs/troubleshooting.md — OFW prompt recipes
