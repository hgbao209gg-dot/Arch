#!/bin/bash

#############################
# Void Linux MUSL Install & Run #
#############################

ROOTFS_DIR="/home/container"
VOID_DATE="20250202"
PROOT_VERSION="5.3.0"

ARCH=$(uname -m)
if [[ "$ARCH" == "x86_64" ]]; then
    ARCH_ALT="x86_64"
elif [[ "$ARCH" == "aarch64" ]]; then
    ARCH_ALT="aarch64"
else
    printf "Unsupported architecture: %s\n" "$ARCH" >&2
    exit 1
fi

ROOTFS_URL="https://repo-default.voidlinux.org/live/current/void-${ARCH_ALT}-musl-ROOTFS-${VOID_DATE}.tar.xz"
TARBALL_PATH="/tmp/void-rootfs.tar.xz"
PROOT_BIN="${ROOTFS_DIR}/usr/local/bin/proot"

# --- Phần Cài Đặt ---
if [[ -e "${ROOTFS_DIR}/.installed" ]]; then
    printf "Void Linux MUSL đã được cài rồi, bỏ qua bước cài đặt...\n"
else
    printf "[*] Đang tải Void Linux MUSL rootfs...\n"
    curl -Lo "$TARBALL_PATH" "$ROOTFS_URL"

    mkdir -p "$ROOTFS_DIR"
    tar -xJf "$TARBALL_PATH" -C "$ROOTFS_DIR"

    printf "[*] Đang tải proot...\n"
    curl -Lo "$PROOT_BIN" \
        "https://github.com/proot-me/proot/releases/download/v${PROOT_VERSION}/proot-v${PROOT_VERSION}-${ARCH}-static"
    chmod 755 "$PROOT_BIN"

    printf "[*] Thiết lập DNS...\n"
    echo "nameserver 1.1.1.1" > "$ROOTFS_DIR/etc/resolv.conf"
    echo "nameserver 1.0.0.1" >> "$ROOTFS_DIR/etc/resolv.conf"

    printf "[*] Dọn rác...\n"
    rm -f "$TARBALL_PATH"

    touch "${ROOTFS_DIR}/.installed"
    printf "Cài đặt hoàn tất! Khởi động môi trường...\n"
fi

printf "[*] Khởi động môi trường Void Linux...\n"
exec "${PROOT_BIN}" \
    --rootfs="$ROOTFS_DIR" \
    --link2symlink \
    --kill-on-exit \
    --root-id \
    --cwd=/root \
    --bind=/proc \
    --bind=/dev \
    --bind=/sys \
    --bind=/tmp \
    /bin/sh -l
