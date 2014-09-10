
# usually called from kernel-source tree, with
#   sh ../build-kernel.sh ../config-3.16-core2-64.v0
# for 32bit an an amd64 use
#   ARCH=i386 sh ../build-kernel.sh ../config-3.16-core2-64.v0

set -x
set -e
[ -f "$1" ]

CONFIG="$(readlink -f "$1")"

CPU_COUNT="$(cat /proc/cpuinfo  | grep  ^processor  | wc -l)"

make mrproper
umask 0022

cat "$CONFIG" > .config
make deb-pkg -j $(($CPU_COUNT + 1)) INSTALL_MOD_STRIP=1
#make binrpm-pkg INSTALL_MOD_STRIP=1
make mrproper

