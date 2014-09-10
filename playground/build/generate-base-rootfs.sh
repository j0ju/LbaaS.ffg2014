#/bin/bash
# generates base debian wheezy filesystem

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
# TODO: ??? via masterless puppet?
EXTRA_PKGS="$EXTRA_PKGS mc tmux screen openssh-server rsync"

# config management
EXTRA_PKGS="$EXTRA_PKGS puppet git"

# TODO: what do we do with user supplied packages?
rm -rf base-rootfs
debootstrap \
  --include="$(echo "$EXTRA_PKGS" | sed -re 's/\s+/,/g' -e 's/^,|,$//g')" \
  wheezy \
  base-rootfs \
# end of debootstrap

# do not start daemons automatically
cat > base-rootfs/usr/sbin/policy-rc.d <<EOF
#!/bin/sh
echo "$0: $*"
exit 101
EOF
chmod a+x base-rootfs/usr/sbin/policy-rc.d

echo root:$ROOTPW | chroot base-rootfs chpasswd

sed -i -e "s/$(hostname)/base-rootfs/" $( grep "$(hostname)" -rl base-rootfs/etc )

cat > base-rootfs/etc/hosts << EOF
# localhost IPv4
127.0.0.1	base-rootfs
127.0.0.1	localhost

# localhost IPv6
# The following lines are desirable for IPv6 capable hosts
::1     ip6-localhost ip6-loopback
fe00::0 ip6-localnet
ff00::0 ip6-mcastprefix
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

