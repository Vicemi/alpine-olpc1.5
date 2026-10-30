# Construir la imagen

Requisitos: Linux x86_64 con Docker y Docker Compose, ~10 GB libres.

```bash
git clone https://github.com/Vicemi/alpine-olpc1.5.git && cd alpine-olpc1.5
docker compose build
docker compose run --rm kernel   # output/kernel/{vmlinuz,config,modules/}
docker compose run --rm image    # output/rootfs/ y output/alpine-xo15.img.xz (+ .sha256)
```

Prueba rápida en QEMU (misma ruta de arranque: tarjeta SDHCI, raíz por PARTUUID, sin initramfs;
no prueba viafb/DCON/WiFi, que son exclusivos de la XO): `scripts/test-qemu.sh` → `output/qemu.log`
y `output/qemu-screen.ppm`.

El código fuente del kernel queda en `output/kernelsrc` (no se vuelve a descargar).

## Qué tocar para cambiar algo

| Quiero... | Archivo |
|---|---|
| Opciones del kernel | `kernel/xo15.config` (el build falla si una opción no queda aplicada) |
| Versión del kernel / rama de Alpine | `docker-compose.yml` (`KVER`, `ALPINE_BRANCH`) |
| Paquetes instalados, servicios, usuario | `scripts/build-rootfs.sh` |
| Archivos de configuración del sistema | `overlay/` (se copia tal cual sobre la raíz) |
| Ajustes de Firefox | `config/firefox-xo.js` |
| Parámetros de arranque del kernel | `boot/olpc.fth` |
| Particiones / tamaño de la imagen | `scripts/make-image.sh` |

## Actualizar el kernel en una XO ya instalada

`/boot` es la partición FAT que lee OFW. Copia el nuevo `vmlinuz` a `/boot/vmlinuz` y los módulos a
`/lib/modules/`, luego `doas depmod -a <versión>`.
