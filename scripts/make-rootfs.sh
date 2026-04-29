#!/bin/bash

set -euo pipefail

# Fixed TZ to ensure consistency
export TZ=UTC

declare -r WRAPPER="fakechroot -- fakeroot"

declare -r GROUP="$1"
declare -r BUILDDIR="$2"
declare -r OUTPUTDIR="$3"
declare -r ARCHIVE_SNAPSHOT="$4"
declare -rx SOURCE_DATE_EPOCH="$5"

# For eventual debugging purposes
echo -e "ARCHIVE_SNAPSHOT: ${ARCHIVE_SNAPSHOT}\nSOURCE_DATE_EPOCH: ${SOURCE_DATE_EPOCH}"

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
if [[ "$GROUP" == "repro" ]]; then
    sed -i "1iServer = https://archive.archlinux.org/repos/$ARCHIVE_SNAPSHOT/\\\$repo/os/\\\$arch" rootfs/etc/pacman.d/mirrorlist
    repro_pacman_options=(
        --logfile /dev/null
    )
fi

$WRAPPER -- \
    pacman -Sy -r "$BUILDDIR" \
        --disable-sandbox-filesystem \
        --noconfirm --dbpath "$BUILDDIR/var/lib/pacman" \
        --config pacman.conf \
        --noscriptlet \
        "${repro_pacman_options[@]}" \
        --hookdir "$BUILDDIR/alpm-hooks/usr/share/libalpm/hooks/" base ${GROUP:+${GROUP/repro/}} # repro is not a package

$WRAPPER -- chroot "$BUILDDIR" update-ca-trust
$WRAPPER -- chroot "$BUILDDIR" pacman-key --init
$WRAPPER -- chroot "$BUILDDIR" pacman-key --populate

if [[ "$GROUP" == "repro" ]]; then
    # Clear pacman keyring for reproducible builds
    rm -rf "$BUILDDIR"/etc/pacman.d/gnupg/*
    # Normalize mtimes
    find "$BUILDDIR" -exec touch --no-dereference --date="@$SOURCE_DATE_EPOCH" {} +
fi

# add system users
$WRAPPER -- chroot "$BUILDDIR" /usr/bin/systemd-sysusers --root "/"

# remove passwordless login for root (see CVE-2019-5021 for reference)
sed -i -e 's/^root::/root:!:/' "$BUILDDIR/etc/shadow"

if [[ "$GROUP" == "repro" ]]; then
    repro_tar_options=(
        --mtime="@$SOURCE_DATE_EPOCH"
        --clamp-mtime
        --sort=name
        --pax-option=delete=atime,delete=ctime
    )
fi

# fakeroot to map the gid/uid of the builder process to root
# fixes #22
fakeroot -- \
    tar \
        --numeric-owner \
        --xattrs \
        --acls \
        "${repro_tar_options[@]}" \
        --exclude-from=exclude \
        -C "$BUILDDIR" \
        -c . \
        -f "$OUTPUTDIR/$GROUP.tar"

cd "$OUTPUTDIR"
zstd --long -T0 -8 "$GROUP.tar"
sha256sum "$GROUP.tar.zst" > "$GROUP.tar.zst.SHA256"
