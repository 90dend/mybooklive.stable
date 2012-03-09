#!/bin/sh

SCRIPT_NAME='wedro_chroot.sh'
SCRIPT_START='99'
SCRIPT_STOP='01'

MOUNT_DIR='/DataVolume/shares'

### BEGIN INIT INFO
# Provides:          $SCRIPT_NAME
# Required-Start:
# Required-Stop:
# X-Start-Before:
# Default-Start:     2 3 4 5
# Default-Stop:
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

CUSTOM_VAR='/var/opt'
CHROOT_DIR="$CUSTOM_VAR/chroot"
CHROOT_SERVICES="$(cat /etc/opt/chroot-services.list)"

check_mounted() {
  if [ -z "$(mount | grep '\/DataVolume\/custom\/var')" ]; then
      echo "CHROOT sems unmounted. exiting"
      exit 1
  fi
}

#######################################################################

start() {
    check_mounted
    mount --bind $MOUNT_DIR $CHROOT_DIR/mnt

    chroot $CHROOT_DIR mount -t proc none /proc -o rw,noexec,nosuid,nodev
    chroot $CHROOT_DIR mount -t sysfs none /sys -o rw,noexec,nosuid,nodev
    chroot $CHROOT_DIR mount -t devpts none /dev/pts -o rw,noexec,nosuid,gid=5,mode=620

    for ITEM in $CHROOT_SERVICES; do
        chroot $CHROOT_DIR service $ITEM start
    done
}

stop() {
    check_mounted
    for ITEM in $CHROOT_SERVICES; do
        chroot $CHROOT_DIR service $ITEM stop
    done

    chroot $CHROOT_DIR umount /dev/pts
    chroot $CHROOT_DIR umount /sys
    chroot $CHROOT_DIR umount /proc

    umount $CHROOT_DIR/mnt
}

#######################################################################

update() {
    chroot $CHROOT_DIR apt-get update
}

upgrade() {
    chroot $CHROOT_DIR apt-get dist-upgrade
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
    update)
        update
    ;;
    upgrade)
        upgrade
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
        echo $"Usage: $0 {start|stop|restart|update|upgrade}"
        exit 1
esac

exit $?

