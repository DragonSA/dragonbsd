#!/bin/sh

if [ -z "$1" ]
then
  exit
fi

. $(dirname $0)/options

DEV=$1

makeBaseImg() {

  cp -p $BTSTRPDIR/boot/loader.conf $WORKDIR/
  echo >> $1/boot/loader.conf
  echo "vfs.root.mountfrom=\"ufs:/dev/ufs/DragonBSDBase\"" >> $BTSTRPDIR/boot/loader.conf

  makefs $WORKDIR/usbimg.ufs $BTSTRPDIR

  mv $WORKDIR/loader.conf $BTSTRPDIR/boot/

}

labelUSB() {

  fdisk -BI $DEV
  bsdlabel -Bwb $BTSTRPDIR/boot/boot ${DEV}s1
  cat > $WORKDIR/bsdlabel << __EOF
8 partitions:
a: $(du -Ak $WORKDIR/usbimg.ufs | cut -f 1)k * 4.2BSD
b: * * 4.2BSD
c: * * unused
__EOF
  bsdlabel -R ${DEV}s1 $WORKDIR/bsdlabel
  rm $WORKDIR/bsdlabel

}

copyBaseImg() {

  dd if=$WORKDIR/usbimg.ufs of=${DEV}s1a bs=64k
  tunefs -L DragonBSDBase ${DEV}s1a
  rm $WORKDIR/usbimg.ufs

}

finishUSB() {

  newfs -EUL DragonBSD ${DEV}s1b

}


makeBaseImg
labelUSB
copyBaseImg
finishUSB
