#!/bin/bash
SIZE=10G
MYPATH="$(dirname "$(readlink -f "$0")")"
BUILDDIR="${MYPATH}/created"
IMGNAME="kvm-playground.raw"
IMG="${BUILDDIR}/${IMGNAME}"
MNT="$( mktemp -d )"
BASEFSDIR="${BUILDDIR}/base-rootfs"

export LC_ALL=C
export DEBIAN_FRONTEND=noninteractive

if [ ! "$(id -u)" = 0 ]; then
  echo "$0 should only be started as root."
  exit 1
fi >&2

set -e
set -x

[ -d "$BUILDDIR" ] || mkdir -p "$BUILDDIR"

rm -f "$IMG"
truncate -s "$SIZE" "$IMG"

parted -s "$IMG" mktable msdos
parted -s "$IMG" mkpart primary ext4 128KiB 2048MiB
parted -s "$IMG" mkpart primary linux-swap 2048MiB 2560MiB

cleanup() {
  for i in 1 2 3; do
    umount $MNT/dev  2>/dev/null || :
    umount $MNT/proc 2>/dev/null || :
    [ -b "$ROOT_P" ] && umount "$ROOT_P" 2>/dev/null || :
    [ -b "$LOOP" ] && kpartx -d "$LOOP" 2> /dev/null || :
    [ -b "$LOOP" ] && losetup -d "$LOOP" 2> /dev/null || :
    grep "$MNT" /proc/mounts || rmdir "$MNT" 2>/dev/null || :
    set +x
  done
}
trap cleanup EXIT INT QUIT TERM

LOOP="$(losetup -fv $IMG | awk '{print $NF}')"
PARTS="$(kpartx -av "$LOOP" | cut -f3 -d\  | tr '\n' ' ')"

parse_partitions() {
  ROOT_P="/dev/mapper/$1"
  SWAP_P="/dev/mapper/$2"
}
parse_partitions $PARTS

# wait for devices to be created
for p in $PARTS; do
  for i in 1 2 3; do
    [ -b "/dev/mapper/$p" ] && break
    sleep 1
  done
  [ -b "/dev/mapper/$p" ] && continue
done

mkfs.ext3 "$ROOT_P" -L playground-root
eval "$(blkid "$ROOT_P" -o export)" && ROOT_UUID="$UUID"
eval "$(mkswap "$SWAP_P" -L playground-swap -f)" && SWAP_UUID="$UUID"

mount "$ROOT_P" "$MNT"
rsync -aH "$BASEFSDIR"/ "$MNT"

cp packages/*.deb "$MNT"/tmp

grub-install --boot-directory="$MNT"/boot "$LOOP"


mount -o bind /dev "$MNT"/dev
chroot "$MNT" /bin/sh -x -e <<EOF
  mount -t proc proc /proc
  apt-get install -y grub-pc initramfs-tools
  dpkg -i /tmp/*.deb
  rm -rf /tmp/*.deb /debian
  umount /proc
EOF

sed -i -re 's@root=[^ ]+@root=UUID='"$ROOT_UUID"'@' "$MNT"/boot/grub/grub.cfg
sed -i -e "s/base-rootfs/playground/" $( grep "base-rootfs" -rl "$MNT"/etc )

cat > "$MNT"/etc/fstab << EOF
# /etc/fstab - $0
proc /proc proc defaults 0 0
cgroup /sys/fs/cgroup cgroup defaults 0 0
tmpfs /tmp tmpfs defaults 0 0
UUID=$ROOT_UUID /    ext3 relatime,errors=remount-ro 0 2
UUID=$SWAP_UUID swap swap defaults 0 2
EOF

