#/bin/bash
# generates base debian wheezy filesystem

MYPATH="$(dirname "$(readlink -f "$0")")"
BUILDDIR="${MYPATH}/created"
BASEFSDIR="${BUILDDIR}/base-rootfs"


if ! [ "$(id -u)" = 0 ]; then
  echo "$0 should only be started as root."
  exit 1
fi >&2

set -e
set -x

ROOTPW=root
EXTRA_PKGS=

# we want to work
EXTRA_PKGS="$EXTRA_PKGS bzip2 xz-utils vim"
# I also want to work
EXTRA_PKGS="$EXTRA_PKGS pv tcpdump atop ifstat"
# TODO: ??? via masterless puppet?
EXTRA_PKGS="$EXTRA_PKGS mc tmux screen openssh-server rsync"

# config management
EXTRA_PKGS="$EXTRA_PKGS puppet git"
# TODO: what do we do with user supplied packages?


[ -d "$BUILDDIR" ] || mkdir -p "$BUILDDIR"
rm -rf $BASEFSDIR
debootstrap \
  --include="$(echo "$EXTRA_PKGS" | sed -re 's/\s+/,/g' -e 's/^,|,$//g')" \
  wheezy \
  $BASEFSDIR \
# end of debootstrap

# do not start daemons automatically
cat > $BASEFSDIR/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
echo "$0: $*"
exit 101
EOF
chmod a+x $BASEFSDIR/usr/sbin/policy-rc.d

echo root:$ROOTPW | chroot $BASEFSDIR chpasswd

sed -i -e "s/$(hostname)/base-rootfs/" $( grep "$(hostname)" -rl $BASEFSDIR/etc )

cat > $BASEFSDIR/etc/hosts << EOF
# localhost IPv4
127.0.0.1	$BASEFSDIR
127.0.0.1	localhost

# localhost IPv6
# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

