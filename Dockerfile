# Root filesystem + image builder (native x86 Alpine, same arch as the XO).
FROM i386/alpine:3.24
RUN apk add --no-cache e2fsprogs e2fsprogs-extra dosfstools mtools sfdisk xz
COPY . /src
ENTRYPOINT ["/bin/sh", "-c", "/src/scripts/build-rootfs.sh && /src/scripts/make-image.sh"]
