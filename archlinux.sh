#!/bin/bash

ROOTFS_DIR=/home/container
PROOT_VERSION="5.3.0"

ARCH=$(uname -m)

if [ "$ARCH" = "x86_64" ]; then
    ROOTFS_URL="https://geo.mirror.pkgbuild.com/iso/2025.08.01/archlinux-bootstrap-2025.08.01-x86_64.tar.zst"
    ROOTFS_FILE="arch-bootstrap-x86_64.tar.zst"
    ROOTFS_UNPACK_PATH="root.x86_64"
elif [ "$ARCH" = "aarch64" ]; then
    ROOTFS_URL="http://os.archlinuxarm.org/os/ArchLinuxARM-aarch64-latest.tar.gz"
    ROOTFS_FILE="archarm-aarch64.tar.gz"
    ROOTFS_UNPACK_PATH=""
else
    echo "Unsupported architecture: $ARCH"
    exit 1
fi

if [ -e "$ROOTFS_DIR/.installed" ]; then
    echo "Arch đã setup sẵn r, khỏi cần nữa"
else
    echo "[*] Đang tải rootfs cho $ARCH..."
    curl -Lo /tmp/$ROOTFS_FILE "$ROOTFS_URL"

    mkdir -p "$ROOTFS_DIR"

    if [ "$ARCH" = "x86_64" ]; then
        echo "[*] Giải nén rootfs x86_64..."
        tar -I zstd -xf /tmp/$ROOTFS_FILE -C /tmp
        mv /tmp/$ROOTFS_UNPACK_PATH/* "$ROOTFS_DIR"
    else
        echo "[*] Giải nén rootfs aarch64..."
        tar -xzf /tmp/$ROOTFS_FILE -C "$ROOTFS_DIR"
    fi

    echo "[*] Tải PRoot static..."
    curl -Lo "$ROOTFS_DIR/usr/local/bin/proot" \
        "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod +x "$ROOTFS_DIR/usr/local/bin/proot"

    echo "[*] Thêm DNS và mirror"
    echo "nameserver 1.1.1.1" > "$ROOTFS_DIR/etc/resolv.conf"
    echo "nameserver 8.8.8.8" >> "$ROOTFS_DIR/etc/resolv.conf"

    if [ "$ARCH" = "x86_64" ]; then
        echo "Server = https://mirror.osbeck.com/archlinux/\$repo/os/\$arch" > "$ROOTFS_DIR/etc/pacman.d/mirrorlist"
    elif [ "$ARCH" = "aarch64" ]; then
        echo "Server = http://sg.mirror.archlinuxarm.org/\$arch/\$repo" > "$ROOTFS_DIR/etc/pacman.d/mirrorlist"
    fi

    touch "$ROOTFS_DIR/.installed"
    rm -rf /tmp/$ROOTFS_FILE /tmp/$ROOTFS_UNPACK_PATH
fi

clear && echo "
────────────────────────────────────────
 ✅ Arch PRoot đã sẵn sàng, chạy thôi nào!
────────────────────────────────────────
"

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
