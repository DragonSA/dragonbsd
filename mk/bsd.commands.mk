# Commands used by DragonBSD

.if !defined(BSD_COMMANDS_MK)
BSD_COMMANDS_MK=	1

BSDLABEL?=	bsdlabel
CDRECORD?=	cdrecord
CHFLAGS?=	chflags
CHMOD?=		chmod
CHOWN?=		chown
CHROOT?=	chroot
CP?=		cp
CUT?=		cut
DD?=		dd
ECHO?=		echo
ENV?=		env
GREP?=		grep
GZIP?=		gzip
FALSE?=		false
FIND?=		find
LN?=		ln
FDISK?=		fdisk
MAKE?=		make
MAKEFS?=	makefs
MKDIR?=		mkdir
MKISOFS?=	mkisofs
MKUZIP?=	mkuzip
MOUNT?=		mount
MV?=		mv
NEWFS?=		newfs
RM?=		rm
SED?=		sed
SORT?=		sort
TAR?=		tar
TOUCH?=		touch
TUNEFS?=	tunefs
UMOUNT?=	umount
UNAME?=		uname

.endif
