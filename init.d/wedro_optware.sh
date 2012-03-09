#!/bin/sh

SCRIPT_NAME='wedro_optware.sh'
SCRIPT_START='90'
SCRIPT_STOP='02'

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

start() {
if [ -d /opt/etc/init.d ]; then
  echo "Launching Optware initialization scripts"
  for f in /opt/etc/init.d/S* ; do
    [ -x $f ] && $f start
  done
else
  echo "error: /opt/etc/init.d directory not found" >&2
  exit 1
fi
}

stop() {
if [ -d /opt/etc/init.d ]; then
  echo "Launching Optware termination scripts"
  for f in /opt/etc/init.d/K* ; do
    [ -x $f ] && $f stop
  done
else
  echo "error: /opt/etc/init.d directory not found" >&2
  exit 1
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
