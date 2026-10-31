# Arquitectura

## Arranque

```
Open Firmware ──(boot-device por defecto)──> u:\boot\olpc.fth  ext:\boot\olpc.fth  int:\boot\olpc.fth
   olpc.fth: unfreeze/visible, detecta el dispositivo, carga \vmlinuz (sin initrd)
Linux 5.15 ──root=PARTUUID=<id>-02 rootwait──> ext4 (p2) ──> OpenRC ──> agetty autologin ──> startx ──> IceWM
```

- **Autoboot.** El valor por defecto de `boot-device` en la XO-1.5 (fuente de OFW,
  `cpu/x86/pc/olpc/via/fw.bth`) es
  `u:\boot\olpc.fth ext:\boot\olpc.fth int:\boot\olpc.fth /prober /usb/ethernet /wlan`.
  Con la seguridad desactivada, OFW ejecuta el primer `\boot\olpc.fth` que encuentra.
- **Por qué con Puppy había que escribir `boot int:\boot\olpc.fth`.** En autoboot OFW deja la
  pantalla **congelada** en el logo (`freeze` → `show-going` congela el DCON justo antes de saltar
  al kernel) y espera que Linux la descongele. Desde el prompt `ok` la pantalla ya está viva. Si el
  driver DCON del kernel no descongela, el autoboot *parece* colgado en el logo aunque esté
  arrancando. Nuestro `olpc.fth` llama a `unfreeze` y `visible` antes de `boot`.
- **Dispositivo.** `olpc.fth` lee `/chosen bootpath` para saber desde dónde se cargó y busca
  `\vmlinuz` en ese mismo dispositivo, así la misma imagen sirve en USB, SD externa o interna.
- **Raíz.** Sin initramfs: MMC, ext4, USB-storage y UHCI/EHCI están compilados en el kernel. La raíz
  se identifica por `PARTUUID` (id del disco MBR + número de partición), estable sin importar si la
  tarjeta es `mmcblk0`, `mmcblk1` o `sda`. En `/etc/fstab` se usan UUIDs de sistema de archivos
  (el `mount` de busybox no entiende `PARTUUID=`; las etiquetas se repiten entre pendrive e interna).
  Los rellena `make-image.sh` y los reescribe `xo-install`.

## Imagen

| Partición | FS | Contenido |
|---|---|---|
| p1 (64 MiB, activa) | FAT32 `XOBOOT` | `\vmlinuz`, `\boot\olpc.fth` — montada en `/boot` |
| p2 | ext4 `xoroot` | Alpine; crece a toda la tarjeta en el primer arranque (`/etc/local.d/10-grow-root.start`) |

La imagen se arma sin dispositivos loop (`mkfs.ext4 -d`, `mtools`, `sfdisk` sobre un archivo), así
el contenedor no necesita `--privileged`.

## Kernel

Linux **5.15 LTS** es la última serie donde `FB_OLPC_DCON` no está marcado `BROKEN`. Base: la config
x86 LTS de Alpine (amplia cobertura de drivers, ya non-PAE) + `kernel/xo15.config`. El script de
build **falla** si alguna opción de `xo15.config` no sobrevive a `olddefconfig` (las dependencias
pueden desactivarlas en silencio; p. ej. `FB_VIA=y` exige `I2C=y`).

Hardware relevante de la XO-1.5: VIA C7-M (hasta 1 GHz), chipset VX855 (gráficos Chrome9 → `viafb`,
USB UHCI/EHCI, audio HDA con códec Conexant), 1 GB DDR2, pantalla 1200×900 con DCON, WiFi Marvell
88W8686 por SDIO (`libertas_sdio` + firmware `linux-firmware-libertas`).

**Firmware:** Alpine lo empaqueta como `.zst`, pero 5.15 solo carga firmware plano o `.xz` (zstd
llegó en 5.19). `overlay/etc/local.d/05-firmware-unzstd.start` lo descomprime en el build y en cada
arranque (por si `apk upgrade` trae `.zst` nuevos).

## Escritorio y memoria

- X.Org con driver `fbdev` sobre `viafb` (no existe driver KMS para VIA; openchrome no está en Alpine).
- IceWM (un solo proceso) en vez de XFCE: menos RAM para el navegador. `~/.xinitrc` lo lanza con
  `dbus-run-session`: `nm-applet` consulta el llavero por el bus de sesión antes de mostrar el
  diálogo de contraseña WiFi, y sin ese bus el diálogo nunca aparece. `~/.icewm/startup` lanza
  `nm-applet` y `dunst` (notificaciones).

## Instalador

`xo-install` (`overlay/usr/local/sbin`) copia el sistema en marcha a otro disco con el mismo esquema
de particiones que la imagen, un PARTUUID nuevo en `olpc.fth` y los UUIDs nuevos en `fstab`.
- Firefox ESR con `config/firefox-xo.js`: un proceso de contenido, sin fission ni animaciones.
- zram 512 MB lz4 como swap.
