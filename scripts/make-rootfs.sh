#!/bin/bash

set -euo pipefail

declare -r WRAPPER="fakechroot -- fakeroot"

declare -r GROUP="$1"
declare -r BUILDDIR="$2"
declare -r OUTPUTDIR="$3"
declare -r ARCHIVE_SNAPSHOT="$4"
declare -rx SOURCE_DATE_EPOCH="$5"

mkdir -vp "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks"
find /usr/share/libalpm/hooks -exec ln -sf /dev/null "$BUILDDIR/alpm-hooks"{} \;

mkdir -vp "$BUILDDIR/var/lib/pacman/" "$OUTPUTDIR"
[[ "$GROUP" == "multilib-devel" ]] && pacman_conf=multilib.conf || pacman_conf=extra.conf
install -Dm644 "/usr/share/devtools/pacman.conf.d/$pacman_conf" "$BUILDDIR/etc/pacman.conf"
cat pacman-conf.d-noextract.conf >> "$BUILDDIR/etc/pacman.conf"

sed 's/Include = /&rootfs/g' < "$BUILDDIR/etc/pacman.conf" > pacman.conf

if grep -q '#DisableSandboxFilesystem' "$BUILDDIR/etc/pacman.conf"; then
sed -i '/#DisableSandboxFilesystem/{c\
# No kernel landlock in containerd\
DisableSandboxFilesystem
}' "$BUILDDIR/etc/pacman.conf"
else
sed -i '/#DisableSandbox/{c\
# No kernel landlock in containerd\
DisableSandbox
}' "$BUILDDIR/etc/pacman.conf"
fi

cp --recursive --preserve=timestamps rootfs/* "$BUILDDIR/"
ln -fs /usr/lib/os-release "$BUILDDIR/etc/os-release"

# Use archived repo snapshot from archive.archlinux.org for reproducible builds
sed -i "1iServer = https://archive.archlinux.org/repos/$ARCHIVE_SNAPSHOT/\\\$repo/os/\\\$arch" "$BUILDDIR/etc/pacman.d/mirrorlist"

$WRAPPER -- \
    pacman -Sy -r "$BUILDDIR" \
        --disable-sandbox-filesystem \
        --noconfirm --dbpath "$BUILDDIR/var/lib/pacman" \
        --config pacman.conf \
        --noscriptlet \
        --hookdir "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks/" base ${GROUP:+${GROUP/repro/}}
#                           # repro is not a package, so excluded here ^

$WRAPPER -- chroot "$BUILDDIR" update-ca-trust
$WRAPPER -- chroot "$BUILDDIR" pacman-key --init
$WRAPPER -- chroot "$BUILDDIR" pacman-key --populate

# Remove archived repo snapshot from the mirrorlist
sed -i '1d' "$BUILDDIR/etc/pacman.d/mirrorlist"

if [[ "$GROUP" == "repro" ]]; 
    # Clear pacman keyring for reproducible builds
    rm -rf "$BUILDDIR"/etc/pacman.d/gnupg/*
fi

# Normalize mtimes
find "$BUILDDIR" -exec touch --no-dereference --date="@$SOURCE_DATE_EPOCH" {} +

# add system users
$WRAPPER -- chroot "$BUILDDIR" /usr/bin/systemd-sysusers --root "/"

# remove passwordless login for root (see CVE-2019-5021 for reference)
sed -i -e 's/^root::/root:!:/' "$BUILDDIR/etc/shadow"

# fakeroot to map the gid/uid of the builder process to root
# fixes #22
fakeroot -- \
    tar \
        --numeric-owner \
        --xattrs \
        --acls \
        --mtime="@$SOURCE_DATE_EPOCH" \
        --clamp-mtime \
        --sort=name \
        --pax-option=delete=atime,delete=ctime \
        --exclude-from=exclude \
        -C "$BUILDDIR" \
        -c . \
        -f "$OUTPUTDIR/$GROUP.tar"

cd "$OUTPUTDIR"
zstd --long -T0 -8 "$GROUP.tar"
sha256sum "$GROUP.tar.zst" > "$GROUP.tar.zst.SHA256"
