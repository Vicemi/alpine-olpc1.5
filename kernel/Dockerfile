# Native 32-bit toolchain (gcc 12) for the XO-1.5 kernel.
FROM i386/debian:bookworm
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential bc bison flex libssl-dev libelf-dev xz-utils kmod cpio curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*
COPY kernel/ /kernel/
ENTRYPOINT ["/kernel/build-kernel.sh"]
