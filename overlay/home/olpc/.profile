# Start the desktop on the autologin console
if [ -z "$DISPLAY" ] && [ "$(tty)" = /dev/tty1 ]; then
    exec startx >/tmp/startx.log 2>&1
fi
