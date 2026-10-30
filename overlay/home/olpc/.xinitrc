xrdb -merge ~/.Xresources
xset s off -dpms   # the DCON keeps the image itself; X blanking just causes flicker
nm-applet &
exec icewm-session
