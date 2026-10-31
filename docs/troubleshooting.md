# Solución de problemas

Para todo lo de abajo: **Esc** al encender → prompt `ok`.

| Síntoma | Qué hacer |
|---|---|
| Arranca otro sistema / no arranca solo | `printenv boot-device`; si no es el de fábrica: `set-default boot-device` y `reset-all`. Un pendrive con `\boot\olpc.fth` siempre gana (USB va primero). |
| Pendrive: `dir u:\` da `Can't open directory` | Ese pendrive falla por USB2. `p2`, luego `dir /pci/usb@10/scsi@0,0/disk:\`; si lista los archivos, `boot /pci/usb@10/scsi@0,0/disk:\boot\olpc.fth`. Para el día a día instala en la interna (`doas xo-install`). |
| Quiero arrancar a mano | `boot int:\boot\olpc.fth` (interna), `ext:` (SD externa), `u:` (USB) |
| `Can't open boot device` | La tarjeta no tiene la partición FAT con `\vmlinuz`. Regrábala. `dir int:\` muestra lo que ve OFW. |
| Mensajes del kernel y se queda en `Waiting for root device` | El PARTUUID de `olpc.fth` no coincide con la tarjeta (p. ej. se copiaron archivos a mano). Regraba la imagen completa. |
| Arranca pero sin entorno gráfico | En consola (`Ctrl+Alt+F2`, usuario `olpc`): `cat /tmp/startx.log`. |
| Al elegir una red no pide contraseña | `~/.xinitrc` debe lanzar la sesión con `dbus-run-session`; sin bus de sesión `nm-applet` no muestra el diálogo. Alternativa: botón **WiFi** (`nmtui`). |
| No aparece WiFi | `dmesg \| grep -i libertas`; `ls /lib/firmware/libertas`; `nmcli device`. |
| Partición no creció | `cat /var/log/grow-root.log` |

Ver el log de arranque: `doas dmesg | less`, `cat /var/log/messages`.
