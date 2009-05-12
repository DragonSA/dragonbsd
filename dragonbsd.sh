#!/bin/sh

. $(dirname $0)/options

# Stage 1: Prepare base system
# Stage 1.1: Uses prepackaged base
# Stage 1.2: Uses prepackaged kernel 
# Stage 1.3: Copy user defined configuration files
#
# Stage 2: Prepare bootstrap from base system
# Stage 2.1: Copy system files
# Stage 2.2: Copy kernel files
# Stage 2.3: Final touches
# Stage 2.4: Retro bootstrap 2
#
# Stage 3: Install additional software
# Stage 3.1: Install ports from packages
# Stage 3.2: Install ports from ports
# Stage 3.3: Run scripts
# Stage 3.4: Copy user defined configuration files
#
# Stage 4: Package system
# Stage 4.1: Package bootstrap
# Stage 4.2: Package bootstrap 2
# Stage 4.3: Package ISO's

stage1() {

  echo ">>> Stage 1: Preparing base system"
  prepareWork
  echo " >>> Stage 1.1: Using prepackaged base"
  extractBase
  echo " >>> Stage 1.2: Using prepackaged kernel"
  extractKernel
  echo " >>> Stage 1.3: Copying user configuration files"
  copyConfig

}

stage2() {

  echo ">>> Stage 2: Preparing bootstrap from base system"
  prepareBootstrap
  echo " >>> Stage 2.1: Copy system files"
  copyBootstrap
  echo " >>> Stage 2.2: Copy kernel files"
  prepareKernel
  copyKernelFiles
  patchKernelConfig
  copyKernel
  compressKernel
  echo " >>> Stage 2.3: Final touches"
  finishBootstrap
  echo " >>> Stage 2.4: Retro bootstrap 2"
  prepareBootstrap2
  copyBootstrap2
  finishBootstrap2

}

stage3() {
  
  echo ">>> Stage 3: Installing additional software"
  echo " >>> Stage 3.1: Installing additional software from packages"
  installPorts
  echo " >>> Stage 3.2: Installing additional software from ports"
  buildPorts
  echo " >>> Stage 3.3: Running scripts"
  runScripts
  echo " >>> Stage 3.4: Copying user configuration files"
  copyConfig

}

stage4() {

  echo ">>> Stage 4: Packaging system"
  echo " >>> Stage 4.1: Package bootstrap"
  packageBootstrap
  echo " >>> Stage 4.2: Package bootstrap 2"
  packageBootstrap2
  echo " >>> Stage 4.3: Packaging ISO images"
  packageISO

}

if [ "$(whoami)" != "root" ]
then
  echo "You are not root, attempting to change to root..."
  echo "Executing: su root - -c $0 $*"
  if ! su root - -c $0 $*
  then
    echo "Unable to change to root, please run $0 as root"
  fi
fi

runstage() {

  if [ "$1" = "-f" ]
  then
    shift
  else
    if [ -e $WORKDIR/.done-$1 ]
    then
      echo ">>> Skipping Stage $(echo $1 | sed 's|stage||')"
      return
    fi 
  fi
  $1
  touch $WORKDIR/.done-$1

}

runallstages() {

  runstage stage1
  runstage stage2
  runstage stage3
  runstage stage4

}

prepareWork() {

  for i in $BASEDIR $WORKDIR $BTSTRPDIR $BTSTRPDIR2
  do
    if [ -e $i ]
    then
      rm -rf $i 2> /dev/null
      if [ -e $i ]
      then
        chflags -R 0 $i
        rm -rf $i
      fi
    fi
  done
  
  mkdir -p $WORKDIR 
  mkdir -p $BASEDIR 
  mkdir -p $BTSTRPDIR
  mkdir -p $BTSTRPDIR2

}

extractBase() {

  tar -C $BASEDIR -xf $WORLDSRC
  if [ ! -e $BASEDIR/libexec/ld-elf32.so.1 ]
  then
    (cd $BASEDIR/libexec ; ln -s ld-elf.so.1 ld-elf32.so.1)
  fi

}

extractKernel() {

  tar -C $BASEDIR -xf $KERNELSRC

}

copyConfig() {

  tar -C $FILESRC -cf - . | tar -C $BASEDIR -xf -

}

prepareBootstrap() {

  for i in $BTSTRPDIRS
  do
    mkdir -p $BTSTRPDIR/$i
  done
  chmod a+w $BTSTRPDIR/tmp

}

copyBootstrap() {

  for i in $BTSTRPDIRS
  do
    i=$(echo $i | cut -d / -f 1)
    for j in $(eval echo \$BTSTRPDIR_$i)
    do
      cp -rf $BASEDIR/$i/$j $BTSTRPDIR/$i/$j
    done
  done

  tar -C $BASEDIR -cf - rescue | tar -C $BTSTRPDIR -xf -

}

prepareKernel() {

  for i in $(find $BASEDIR/boot -type d -depth 1)
  do
    mkdir $BTSTRPDIR/boot/$(basename $i)
  done

}

copyKernelFiles() {

  for i in $(find $BASEDIR/boot -type f -depth 1)
  do
    cp -fp $i $BTSTRPDIR/boot
  done
  if [ -d $BASEDIR/boot/defaults ]
  then
    cp -fp $BASEDIR/boot/defaults/* $BTSTRPDIR/boot/defaults
  fi
  if [ -f $BASEDIR/usr/lib/kgzldr.o ]
  then
    mkdir -p $BTSTRPDIR/usr/lib
    cp -fp $BASEDIR/usr/lib/kgzldr.o $BTSTRPDIR/usr/lib
  fi

}

patchKernelConfig() {

  CONF=$BTSTRPDIR/boot/loader.conf
  echo >> $CONF

  for i in $BTSTRPMODULES
  do
    if [ -z "$(grep ^${i}_load=\"[Yy][Ee][Ss]\".\* $CONF)" ]
    then
      echo ${i}_load=\"YES\" >> $CONF
    fi
  done

  echo init_script=\"/chroot\" >> $CONF
  echo init_chroot=\"/base\" >> $CONF

}

copyKernel() {

  cp -fp $BASEDIR/boot/kernel/kernel $BTSTRPDIR/boot/kernel
  if [ -e $BASEDIR/boot/kernel/acpi.ko ]
  then
    cp -fp $BASEDIR/boot/kernel/acpi.ko $BTSTRPDIR/boot/kernel
  fi
  for i in $(grep '[0-9A-Za-z_]_load="[Yy][Ee][Ss]".*' $BTSTRPDIR/boot/loader.conf | sed 's|_load="[Yy][Ee][Ss]".*||g' )
  do
    if [ -e $BASEDIR/boot/kernel/$i.ko ]
    then
      cp -fp $BASEDIR/boot/kernel/$i.ko $BTSTRPDIR/boot/kernel
    elif [ -e $BASEDIR/boot/modules/$i.ko ]
    then
      cp -fp $BASEDIR/boot/modules/$i.ko $BTSTRPDIR/boot/modules
    fi
  done

}

compressKernel() {

  gzip -f9 $BTSTRPDIR/boot/kernel/*

}

finishBootstrap() {

  #cp -p $BASEDIR/sbin/ldconfig $BTSTRPDIR/sbin   #
  #chroot $BTSTRPDIR /sbin/ldconfig /lib          # Moved to rescue, no longer need ldconfig
  #rm $BTSTRPDIR/sbin/ldconfig                    #

  cat > $BTSTRPDIR/chroot << _EOF
#!/rescue/sh
PATH=/rescue
trap 'echo Recovery console: ; PATH=/rescue /rescue/csh -i ; exit' 1 2 3 6 15

echo "Mounting compressed base:"
mount -o ro /dev/\$(mdconfig -a -t vnode -o readonly -f /base.uzip).uzip /base 

if [ -w /dev/ufs/DragonBSD ]
then
  echo "Overlaying filesystem:"
  mount /dev/ufs/DragonBSD /tmp
  mount -t unionfs -o noatime -o copymode=transparent /tmp /base
else
  echo "Allocating temporary filesystem:"
  mdmfs -s 32m md /tmp

  echo "Overlaying temporary filesystem:"
  mount -t unionfs -o noatime -o copymode=transparent /tmp /base
fi

mount -t devfs devfs /base/dev

echo "Chroot to base..."
_EOF
  chmod a+x $BTSTRPDIR/chroot
  chmod a+rwx $BTSTRPDIR/tmpfs

}

prepareBootstrap2() {



}

copyBootstrap2() {

  cp -rfp $BTSTRPDIR/boot $BTSTRPDIR2/
  if [ -f $BTSTRPDIR/usr/lib/kgzldr.o ]
  then
    mkdir -p $BTSTRPDIR2/usr/lib
    cp -fp $BTSTRPDIR/usr/lib/kgzldr.o $BTSTRPDIR2/usr/lib/
  fi

}

finishBootstrap2() {

  cat >> $BTSTRPDIR2/boot/loader.conf << _EOF
dragonroot_load="YES"
dragonroot_type="mfs_root"
dragonroot_name="/boot/dragonroot"
vfs.root.mountfrom="ufs:/dev/ufs/DragonBSDBase"
_EOF

}

installPorts() {

  if [ -z "$PKGS" ]
  then
    return
  fi

  mount -t nullfs $PKGDIR $BASEDIR/tmp
  mount -t devfs devfs $BASEDIR/dev

  cat > $BASEDIR/installPorts.sh << _EOF
#!/bin/sh
cd /tmp
for i in $PKGS
do
  if [ -e /tmp/\$i ]
  then
    pkg_add /tmp/\$i
  else
    for j in \$(find . -name "*\$i*" -depth 1)
    do
      pkg_add \$j
    done
  fi
done
_EOF
  chmod a+x $BASEDIR/installPorts.sh
  chroot $BASEDIR /installPorts.sh
  rm $BASEDIR/installPorts.sh

  umount $BASEDIR/dev
  umount $BASEDIR/tmp

}

buildPorts() {

  if [ -z "$PORTS" ]
  then
    return
  fi

  mkdir -p $BASEDIR/usr/ports
  mkdir -p $BASEDIR/usr/freebsd
  mount -t nullfs /usr/ports $BASEDIR/usr/ports
  mount -t nullfs /usr/freebsd $BASEDIR/usr/freebsd
  mount -t devfs devfs $BASEDIR/dev
  mount -t tmpfs tmpfs $BASEDIR/tmp

  cat > $BASEDIR/buildPorts.sh << _EOF
#!/bin/sh
echo WRKDIRPREFIX=/tmp >> /etc/make.conf
for i in $PORTS
do
  if [ -d /usr/ports/\$i ]
  then
    make -C /usr/ports/\$i all install clean BATCH=yes
  fi
done
_EOF
  chmod a+x $BASEDIR/buildPorts.sh
  chroot $BASEDIR ./buildPorts.sh
  rm $BASEDIR/buildPorts.sh

  umount $BASEDIR/tmp
  umount $BASEDIR/dev
  umount $BASEDIR/usr/freebsd
  umount $BASEDIR/usr/ports

}

runScripts() {

  if [ "$SCRIPTS" = "*" ]
  then
    SCRIPTS=`find $SCRIPTSDIR -depth 1 -type f -perm +0111 -execdir echo {} +`
  fi

  for i in $SCRIPTS
  do
    if [ -e $SCRIPTSDIR/$i ]
    then
      S=$i
    else
      S=$i.sh
    fi
    cp -fp $SCRIPTSDIR/$S $BASEDIR
    chroot $BASEDIR /$S
    rm $BASEDIR/$S
  done

}

packageBootstrap() {

  makefs $BTSTRPDIR/base.ufs $BASEDIR
  mkuzip -s 8192 -o $BTSTRPDIR/base.uzip $BTSTRPDIR/base.ufs
  rm $BTSTRPDIR/base.ufs

}

packageBootstrap2() {

  cp -p $BTSTRPDIR/chroot $WORKDIR/chroot
  mv $BTSTRPDIR/boot $WORKDIR/
  cat >> $BTSTRPDIR/chroot << _EOF

CD_DEV=\$(dmesg | sed -n -e 's|.* a\(cd[0-9]*\) .*iso9660/DragonBSD.*|\1|p' | sed '1 q')
if [ -n "\$CD_DEV" ]
then
  echo "Ejecting CD-ROM..."
  camcontrol eject \$CD_DEV
fi
_EOF

  makefs $BTSTRPDIR2/boot/dragonroot $BTSTRPDIR
  tunefs -L DragonBSDBase $BTSTRPDIR2/boot/dragonroot
  gzip -f9 $BTSTRPDIR2/boot/dragonroot

  mv $WORKDIR/boot $BTSTRPDIR/
  mv $WORKDIR/chroot $BTSTRPDIR/chroot

}

packageISO() {

  patchLoader() {

    cp -p $1/boot/loader.conf $WORKDIR/
    echo >> $1/boot/loader.conf
    echo "vfs.root.mountfrom=\"cd9660:/dev/iso9660/DragonBSD\"" >> $1/boot/loader.conf

  }

  unpatchLoader() {

    mv $WORKDIR/loader.conf $1/boot/

  }

  patchLoader $BTSTRPDIR
  mkisofs $MKISOFLAGS -b boot/cdboot --no-emul-boot -volid DragonBSD -o $WORKDIR/DragonBSD.iso $BTSTRPDIR 
  unpatchLoader $BTSTRPDIR

  mkisofs $MKISOFLAGS -b boot/cdboot --no-emul-boot -volid DragonBSD -o $WORKDIR/DragonBSD2.iso $BTSTRPDIR2

  patchLoader $BASEDIR
  mkisofs $MKISOFLAGS -b boot/cdboot --no-emul-boot -volid DragonBSD -o $WORKDIR/DragonBSD3.iso $BASEDIR
  unpatchLoader $BASEDIR

}

if [ "$#" = "0" ]
then
  runallstages
else
  case $1 in
    rebuild)
      FORCESG4=$(if [ -e $WORKDIR/.done-stage4 ]; then echo true; fi)
      runallstages
      if [ -n "$FORCESG4" ]
      then
        runstage -f stage4
      fi
      ;;
    rebuildiso)
      packageISO
      ;;
    clean)
      for i in `mount | grep $WORKDIR | cut -f 3 -d ' ' | sort -r`
      do 
        umount $i
      done
      chflags -R 0 $WORKDIR
      rm -rf $WORKDIR
      ;;
  esac
fi

