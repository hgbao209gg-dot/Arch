#!/bin/sh

ROOTFS_DIR=/home/container
PROOT_VERSION="5.3.0"

ARCH=$(uname -m)
if [ "$ARCH" = "x86_64" ]; then
    ARCH_PD="x86_64"
elif [ "$ARCH" = "aarch64" ]; then
    ARCH_PD="aarch64"
elif [ "$ARCH" = "armv7l" ]; then
    ARCH_PD="arm"
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

DEBIAN_VERSION="trixie"
DEBIAN_TARBALL="https://github.com/termux/proot-distro/releases/download/v4.26.0/debian-${DEBIAN_VERSION}-${ARCH_PD}-pd-v4.26.0.tar.xz"

if [ -e "$ROOTFS_DIR/.installed" ]; then
    echo "Debian đã được cài rồi, skip bước cài đặt"
else
    echo "[*] Đang tải Debian rootfs..."
    curl -Lo /tmp/rootfs.tar.xz "$DEBIAN_TARBALL"

    mkdir -p "$ROOTFS_DIR"
    tar -xJf /tmp/rootfs.tar.xz -C "$ROOTFS_DIR"

    echo "[*] Đang tải proot..."
    curl -Lo "$ROOTFS_DIR/usr/local/bin/proot" \
        "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 "$ROOTFS_DIR/usr/local/bin/proot"

    echo "[*] Set DNS"
    echo "nameserver 1.1.1.1" > "$ROOTFS_DIR/etc/resolv.conf"
    echo "nameserver 1.0.0.1" >> "$ROOTFS_DIR/etc/resolv.conf"

    echo "[*] Cleanup..."
    rm -f /tmp/rootfs.tar.xz

    touch "$ROOTFS_DIR/.installed"
fi

clear && cat << "EOF"
██████╗ ███████╗██████╗ ██╗███████╗ █████╗ ███╗   ██╗
██╔══██╗██╔════╝██╔══██╗██║██╔════╝██╔══██╗████╗  ██║
██║  ██║█████╗  ██████╔╝██║███████╗███████║██╔██╗ ██║
██║  ██║██╔══╝  ██╔══██╗██║╚════██║██╔══██║██║╚██╗██║
██████╔╝███████╗██║  ██║██║███████║██║  ██║██║ ╚████║
╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═══╝
Welcome to Debian ${DEBIAN_VERSION} rootfs!
EOF

"$ROOTFS_DIR/usr/local/bin/proot" \
    --rootfs="$ROOTFS_DIR" \
    --link2symlink \
    --kill-on-exit \
    --root-id \
    --cwd=/root \
    --bind=/proc \
    --bind=/dev \
    --bind=/sys \
    --bind=/tmp \
    /bin/bash
