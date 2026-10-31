# Alpine Linux para la OLPC XO-1.5

Alpine Linux 3.24 (x86, 32-bit) instalado de verdad (no live) para la **XO-1.5**: escritorio
**IceWM**, **Firefox ESR**, **WiFi** (Marvell Libertas 8686) con NetworkManager, y **arranque
automático** sin escribir nada en el prompt `ok`.

| | |
|---|---|
| Kernel | Linux 5.15 LTS propio: non-PAE (el VIA C7 no arranca PAE), driver DCON, viafb, sin initramfs |
| Escritorio | IceWM + PCManFM + LXTerminal, autologin en `tty1` → `startx` (sin display manager) |
| Red | NetworkManager + `nm-applet` (icono en la barra), firmware `sd8686` |
| Navegador | Firefox ESR con ajustes para 1 GB de RAM (1 proceso, sin animaciones) |
| Memoria | swap comprimida en RAM (zram 512 MB, lz4) |

Usuario: **`olpc`**, contraseña **`olpc`** — cámbiala con `passwd`. La cuenta `root` está bloqueada:
para administrar usa `doas` (p. ej. `doas apk add gimp`) con la contraseña de `olpc`.

## Instalar en la XO

Requisito: la XO tiene la seguridad desactivada (llegas al prompt `ok` con la tecla Esc al
arrancar). Ya es tu caso si usabas Puppy.

1. Descarga `alpine-xo15.img.xz` de [Releases](https://github.com/Vicemi/alpine-olpc1.5/releases).
2. Grábala en la tarjeta (o en un pendrive para probar primero, ver abajo):
   - **Windows:** [balenaEtcher](https://etcher.balena.io/) o [Rufus](https://rufus.ie) (aceptan el `.xz` directo).
   - **Linux:** `xz -dc alpine-xo15.img.xz | sudo dd of=/dev/sdX bs=4M conv=fsync status=progress`
3. Pon la tarjeta en la XO y enciende. Arranca sola.

En el primer arranque la partición raíz se agranda para ocupar toda la tarjeta (unos segundos).

### Instalar en la microSD interna sin sacarla

1. Arranca Alpine desde un pendrive (ver abajo).
2. Abre la Terminal y ejecuta `doas xo-install`. Muestra los discos con su tamaño y etiquetas
   (la interna es la de ~16 GB; si tenía Puppy verás la etiqueta `PUPPYXO`), pide el disco destino
   (p. ej. `/dev/mmcblk0`) y que escribas `BORRAR`.
3. Copia el sistema que está corriendo (incluidas las redes WiFi guardadas). Al terminar apaga,
   quita el USB y enciende: arranca solo desde la interna.

### Probar primero sin tocar la microSD interna

La misma imagen arranca desde **pendrive USB** o desde la **ranura SD externa**: OFW busca
`\boot\olpc.fth` en este orden: USB (`u:`), SD externa (`ext:`), SD interna (`int:`). Graba un
pendrive, conéctalo y enciende: arranca desde el pendrive aunque la interna tenga otro sistema.

Algunos pendrives no funcionan por el USB2 de la XO (`dir u:\` da `Can't open directory`). En ese
caso, desde `ok`: `p2`, luego `dir /pci/usb@10/scsi@0,0/disk:\` (el mismo pendrive por USB1) y, si
lista `VMLINUZ` y `BOOT`, arranca con `boot /pci/usb@10/scsi@0,0/disk:\boot\olpc.fth`.

### WiFi
Clic en el icono de red de la barra → elige la red → aparece el diálogo de contraseña. También
está el botón **WiFi** de la barra (menú de texto `nmtui`), o desde la Terminal:
`nmcli device wifi connect "MiRed" password "clave"`.

## Si no arranca solo

1. Pulsa **Esc** al encender para llegar a `ok` y mira qué busca el firmware:
   ```
   printenv boot-device
   ```
   Debe ser `u:\boot\olpc.fth ext:\boot\olpc.fth int:\boot\olpc.fth ...`. Si alguna vez lo
   cambiaste, vuelve al valor de fábrica con `set-default boot-device` y `reset-all`.
2. Si queda el logo OLPC fijo: este `olpc.fth` descongela la pantalla antes de arrancar Linux,
   así que deberías ver mensajes; si no los ves, abre un issue con una foto de la pantalla.

Más detalles: [docs/troubleshooting.md](docs/troubleshooting.md).

## Construir la imagen

Docker en Linux (x86_64). Ver [docs/building.md](docs/building.md).
```bash
docker compose run --rm kernel   # ~30-60 min
docker compose run --rm image    # -> output/alpine-xo15.img.xz
```

## Documentación
- [docs/architecture.md](docs/architecture.md) — cómo arranca y por qué cada decisión
- [docs/building.md](docs/building.md) — construir y modificar la imagen
- [docs/troubleshooting.md](docs/troubleshooting.md) — problemas conocidos
