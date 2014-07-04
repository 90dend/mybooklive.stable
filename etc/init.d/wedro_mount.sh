#!/bin/sh

SCRIPT_NAME='wedro_mount.sh'
SCRIPT_START='01'
SCRIPT_STOP='99'

### BEGIN INIT INFO
# Provides:          $SCRIPT_NAME
# Required-Start:
# Required-Stop:     wedro_chroot.sh
# X-Start-Before:
# Default-Start:     2 3 4 5
# Default-Stop:      0 6
### END INIT INFO

script_install() {
  cp $0 /etc/init.d/$SCRIPT_NAME
  chmod a+x /etc/init.d/$SCRIPT_NAME
  update-rc.d $SCRIPT_NAME defaults $SCRIPT_START $SCRIPT_STOP > /dev/null
}

script_remove() {
  update-rc.d -f $SCRIPT_NAME remove > /dev/null
  rm -f /etc/init.d/$SCRIPT_NAME
}

#######################################################################

CUSTOM="/DataVolume/custom"
C_OPT="$CUSTOM/opt"
C_ROOT="$CUSTOM/root"
C_VAR="$CUSTOM/var"
C_ETC="$CUSTOM/etc"
C_CHROOT="$CUSTOM/chroot"

###################################################

start() {
if [ -z "$(mount | grep '\/opt')" ]; then
  echo "Mounting OPTWARE"
  mount --bind $C_OPT /opt
else
  echo "Error: OPTWARE seems already mounted" >&2
fi

if [ -z "$(mount | grep '\/root')" ]; then
  echo "Mounting ROOT"
  mount --bind $C_ROOT /root
else
  echo "Error: ROOT seems already mounted" >&2
fi

if [ -z "$(mount | grep '\/var\/opt')" ]; then
  echo "Mounting VAR/OPT"
  mount --bind $C_VAR /var/opt
else
  echo "Error: VAR/OPT seems already mounted" >&2
fi

if [ -z "$(mount | grep '\/etc\/opt')" ]; then
  echo "Mounting ETC/OPT"
  mount --bind $C_ETC /etc/opt
else
  echo "Error: ETC/OPT seems already mounted" >&2
fi

if [ -z "$(mount | grep '\/srv\/chroot')" ]; then
  echo "Mounting SRV/CHROOT"
  mkdir -p /srv/chroot
  mount --bind $C_CHROOT /srv/chroot
else
  echo "Error: SRV/CHROOT seems already mounted" >&2
fi

}

stop() {
if [ -n "$(mount | grep '\/opt')" ]; then
  echo "Unmounting OPTWARE"
  umount -l /opt
else
  echo "Error: OPTWARE seems already unmounted" >&2
fi

if [ -n "$(mount | grep '\/root')" ]; then
  echo "Unmounting ROOT"
  umount -l /root
else
  echo "Error: ROOT seems already unmounted" >&2
fi

if [ -n "$(mount | grep '\/var\/opt')" ]; then
  echo "Unmounting VAR/OPT"
  umount /var/opt
else
  echo "Error: VAR/OPT seems already unmounted" >&2
fi

if [ -n "$(mount | grep '\/etc\/opt')" ]; then
  echo "Unmounting ETC/OPT"
  umount /etc/opt
else
  echo "Error: ETC/OPT seems already unmounted" >&2
fi

if [ -n "$(mount | grep '\/srv\/chroot')" ]; then
  echo "Unmounting SRV/CHROOT"
  umount /srv/chroot
else
  echo "Error: SRV/CHROOT seems already unmounted" >&2
fi

}

#######################################################################

case "$1" in
    start)
        start
    ;;
    stop)
        stop
    ;;
    restart)
        stop
        sleep 1
        start
    ;;
    install)
        script_install
    ;;
    init)
        script_install
        sleep 1
        start
    ;;
    remove)
        stop
        sleep 1
        script_remove
    ;;
    *)
        echo $"Usage: $0 {start|stop|restart}"
        exit 1
esac

exit $?
