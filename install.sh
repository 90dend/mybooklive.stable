#!/bin/sh

CUSTOM="/DataVolume/custom"
C_ROOT="$CUSTOM/root"
C_OPT="$CUSTOM/opt"
C_VAR="$CUSTOM/var"
C_ETC="$CUSTOM/etc"
C_CHROOT="$CUSTOM/chroot"

QUO="/DataVolume/quo"

CHROOT_DIR='/srv/chroot'

#############################################

if [ -d $QUO ]; then
  chmod -R a+x $QUO/etc
  chmod -R a+x $QUO/sbin
  chmod a+x $QUO/extra/infect/wedroInfectRootfs.sh
  chmod a+x $QUO/install.sh
fi

#############################################

return_quo() {
echo 'Set up user customizations =)'
cd /

## PREPARING Custom dirs
if [ ! -d $C_ROOT ]; then
  mkdir -p $C_ROOT
  mkdir -p $C_ROOT/.bin
  mv -fu /root/* -t $C_ROOT
  mv -fu /root/.* -t $C_ROOT
fi

if [ ! -d $C_OPT ]; then
  mkdir -p $C_OPT
fi

if [ ! -d $C_VAR ]; then
  mkdir -p $C_VAR
fi

if [ ! -d $C_ETC ]; then
  mkdir -p $C_ETC
fi

if [ ! -d $C_CHROOT ]; then
  mkdir -p $C_CHROOT
fi

#############################################

## HDD magic
echo 'HDD: fighting annoying parking'
$QUO/sbin/idle3ctl -d /dev/sda

#############################################

## MOUNT magic
  echo 'MOUNT: enabling necessary binded mounts at boot'
  $QUO/etc/init.d/wedro_mount.sh init

#############################################

## OPTWARE magic
if [ -z "$(ls /opt)" ]; then
  echo "OPTWARE: is not installed. You should fix it with [$0 optware]"
  OPTWARE='1'
else
  script_optware
fi

#############################################

## CHROOT magic
if [ ! -d $CHROOT_DIR ]; then
  echo "CHROOT: dir is absent. You should fix it with [$0 chroot]"
  CHROOT='1'
elif [ -z "$(ls $CHROOT_DIR)" ]; then
  echo "CHROOT: is empty. You should fix it with [$0 chroot]"
  CHROOT='1'
else
  script_chroot
fi

#############################################

## ETC magic
locale-gen

# Root utilities
cp $QUO/extra/bin/* /root/.bin
chmod -R a+x /root/.bin

# Settings
touch /etc/opt/chroot-services.list

if [ "$ZERO" != '1' ]; then
  chmod a+x /etc/opt/restore-configs.sh
  /etc/opt/restore-configs.sh
else
  touch /etc/opt/restore-configs.sh
  chmod a+x /etc/opt/restore-configs.sh
fi

# PATH
if [ -z "$(cat /root/.profile | grep 'PATH' | grep '\/root\/.bin')" ]; then
  echo -e 'export PATH=$PATH:/root/.bin' >> /etc/profile
fi

#############################################

export PATH=$PATH:/root/.bin

echo 'Returning finished!'
echo 'WD MyBook Live will REBOOT!'
reboot
}

#######################################################################################
#######################################################################################

return_optware() {
  echo 'OPTWARE: installing...'
  OLD_PWD=$PWD
  cd /tmp
  ## FIXME  
  #cp $QUO/pkg/ipkg-opt_0.99.163-10_powerpc.ipk /tmp
  $QUO/sbin/setup-mybooklive.sh > /dev/null
  cd $OLD_PWD
  ipkg update
  ipkg install htop mc screen patch py27-mercurial

  script_optware
}

script_optware() {
  echo 'OPTWARE: enabling init scripts'
  $QUO/etc/init.d/wedro_optware.sh install

  if [ -z "$(cat /etc/profile | grep 'PATH' | grep '\/opt\/')" ]; then
    echo 'ETC: fixing PATH for optware use'
    echo -e 'export PATH=$PATH:/opt/bin:/opt/sbin' >> /etc/profile
  fi

}

#######################################################################################
#######################################################################################

return_chroot() {
  dpkg -i $QUO/extra/pkg/debootstrap_1.0.10lenny1_all.deb > /dev/null
  ln -s -f /usr/share/debootstrap/scripts/sid /usr/share/debootstrap/scripts/testing
  if [ -z "$(mount | grep $C_CHROOT)" ]; then
    echo "CHROOT: custom /VAR was unmounted. Fixing..."
    mount --bind $C_CHROOT $CHROOT_DIR
  fi
  if [ ! -d $CHROOT_DIR ]; then
    echo "CHROOT: chroot dir was absent. Fixing..."
    mkdir -p $CHROOT_DIR
  fi
  debootstrap --variant=minbase --exclude=yaboot,udev,dbus --include=mc,aptitude testing $CHROOT_DIR http://cdn.debian.net/debian/
  echo 'chroot' > $CHROOT_DIR/etc/debian_chroot
  sed -i 's/^\(export PS1.*\)$/#\1/g' $CHROOT_DIR/root/.bashrc
  chroot $CHROOT_DIR apt-get -y update
  chroot $CHROOT_DIR apt-get -y install htop mc screen upgrade-system

  script_chroot
}

script_chroot() {
  echo 'CHROOT: enabling debian custom services in chroot'
  $QUO/etc/init.d/wedro_chroot.sh install
}

#######################################################################################
#######################################################################################

do_zero() {
#  check internet connection
  ZERO='1'
  return_quo
  if [ "$OPTWARE" == '1' ]; then
    return_optware
  fi
  if [ "$CHROOT" == '1' ]; then
    return_chroot
  fi
  update_quo
}

#######################################################################################
#######################################################################################

update_quo() {
PATH="$PATH:/opt/sbin:/opt/bin"
if [ -z "$(ipkg status py27-mercurial | grep 'Status:' | grep 'installed')" ]; then
  ipkg update
  ipkg install py27-mercurial
fi
if [ ! -d $QUO/.hg ]; then
  mv -f $QUO $QUO.old
  hg-py2.7 clone https://dhameoelin@code.google.com/p/mybooklive/ $QUO
#  echo -e '[hostfingerprints]\ncode.google.com = e2:9e:46:29:a0:fd:3c:57:a0:68:30:c5:0a:45:97:63:bf:8d:75:fc' >> $QUO/.hg/hgrc
  rm -rf $QUO.old
else
  OLD_PWD=$PWD
  cd $QUO
  hg-py2.7 pull && hg-py2.7 update
  cd $OLD_PWD
fi
chmod a+x $QUO/install.sh
chmod -R a+x $QUO/etc/init.d
chmod -R a+x $QUO/sbin
}

#######################################################################################
#######################################################################################

update_scripts() {
  SCRIPTS="wedro_mount.sh wedro_optware.sh wedro_chroot.sh"
  for ITEM in $SCRIPTS; do
    $QUO/etc/init.d/$ITEM remove
    $QUO/etc/init.d/$ITEM install
  done
}

#######################################################################################
#######################################################################################
#######################################################################################

case "$1" in
    init)
        return_quo
    ;;
    optware)
        return_optware
    ;;
    chroot)
        return_chroot
    ;;
    update)
        update_quo
    ;;
    setup)
        do_zero
    ;;
    renew)
        update_scripts
    ;;
    *)
        echo $"Usage: $0 {setup (!) | init | optware (*) | chroot (*) | update (*) }"
        echo "(*) - internet connection and completed [init] section required"
        echo "(!) [setup] will do complete installation on new system: [init], [optware], [chroot] and [update]"
        echo "[init] will (re)set up scripts and configs & mount /opt, /root and /var/opt into /DataVolume"
        echo "[optware] will install Optware into /opt"
        echo "[chroot] will install Debian testing via debootstrap into $CHROOT_DIR"
        echo "[update] will update QUO with mercurial (install hg-py27 before if none detected)"
        exit 1
esac

exit $?
