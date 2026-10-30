\ OLPC boot script - Alpine Linux for the XO-1.5
\ Found automatically by Open Firmware: its default boot-device is
\ "u:\boot\olpc.fth ext:\boot\olpc.fth int:\boot\olpc.fth" (USB, SD slot, internal SD).

\ Autoboot "freezes" the DCON on the OLPC logo and expects Linux to unfreeze it.
\ Unfreeze now so boot messages are visible and a frozen logo can never look like a hang.
unfreeze
visible

\ Boot from the same device this script was loaded from (u:, ext: or int:).
" int:" dn-buf place
" /chosen" find-package  if
   " bootpath" rot get-package-property  0=  if
      get-encoded-string  [char] \ left-parse-string  2nip  dn-buf place
   then
then

" ${DN}\vmlinuz" expand$ to boot-device
" " to ramdisk
" root=PARTUUID=@PARTUUID@-02 rootwait ro console=tty0 loglevel=4" to boot-file
boot
