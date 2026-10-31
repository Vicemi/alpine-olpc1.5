xrdb -merge ~/.Xresources
xset s off -dpms   # the DCON keeps the image itself; X blanking just causes flicker
# A session D-Bus is required: nm-applet asks the keyring over it before showing the
# WiFi password dialog, and without it the dialog never appears.
exec dbus-run-session icewm-session
