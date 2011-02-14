# The name of the system
NAME?=		DragonBSD
NAME_BTSTRP?=	${NAME}BTSTRP
NAME_LIVE?=	${NAME}Live
NAME_MEM_LIVE?=	${NAME}MEMLive
NAME_UFS?=	${NAME}UFS

MDMFS_SIZE?=	32m
CHROOT_SCRIPT?=	${.CURDIR}/chroot

## Kernel/world build options
SRCDIR?=	/usr/src
KERNCONF?=	GENERIC
TARGET?=	${UNAME_p}

## Working directories
UNAME_p!=	${UNAME} -p
WRKSRC?=	${.CURDIR}
. if ${TARGET} == ${UNAME_p}
WRKDIR?=	${WRKSRC}/${NAME}
.else
WRKDIR?=	${WRKSRC}/${NAME}-${TARGET}
.endif
BASEDIR?=	${WRKDIR}/base
BOOTSTRAPDIR?=	${WRKDIR}/bootstrap
LOADERBOOTSTRAPDIR?=	${WRKDIR}/loader_bootstrap

## Source files
DISTFILES?=	${PWD}/distfiles
FILESRC?=	${PWD}/files
SCRIPTSDIR?=	${_MASTERSCRIPTSDIR}
_MASTERSCRIPTSDIR= ${.CURDIR}/scripts

.if ${TARGET} == ${UNAME_p}

PKGDIR?=	${DISTFILES}/packages

.  if ${KERNCONF} == GENERIC
KERNELSRC?=	${DISTFILES}/kernel.tar.xz
.  else
KERNELSRC?=	${DISTFILES}/kernel-${KERNCONF}.tar.xz
.  endif
PKG_ENV_DIR?=	/home/pkg_env
WORLDSRC?=	${DISTFILES}/world.tar.xz

.else

PKGDIR?=	${DISTFILES}/packages-${TARGET}

.  if ${KERNCONF} == GENERIC
KERNELSRC?=	${DISTFILES}/kernel-${TARGET}.tar.xz
.  else
KERNELSRC?=	${DISTFILES}/kernel-${KERNCONF}-${TARGET}.tar.xz
.  endif
PKG_ENV_DIR?=	/home/pkg_env_${TARGET}
WORLDSRC?=	${DISTFILES}/world-${TARGET}.tar.xz

.endif

PKGS?=
PORTS?=
SCRIPTS?=

## Bootstrap information
BOOTSTRAPDIRS+=		base boot dev overlay usr/lib
BOOTSTRAPFILES+=	etc/login.conf
BOOTSTRAPMODULES+=	zlib geom_uzip unionfs

## Target images
BASECOMPRESSEDIMAGE?=		${WRKDIR}/base.ufs.uzip
BOOTSTRAPCOMPRESSEDIMAGE?=	${WRKDIR}/bootstrap.ufs.gz
ISOFILE?=			${WRKDIR}/${NAME:L}.iso
ISOMEMLIVEFILE?=		${WRKDIR}/${NAME:L}-mem-live.iso
ISOLIVEFILE?=			${WRKDIR}/${NAME:L}-live.iso
UFSFILE?=			${WRKDIR}/${NAME:L}.ufs
UFSLIVEFILE?=			${WRKDIR}/${NAME:L}-live.ufs
UFSMEMLIVEFILE?=		${WRKDIR}/${NAME:L}-mem-live.ufs

## Sundry
MKISOFLAGS=	-quiet -sysid FREEBSD -rock -untranslated-filenames -max-iso9660-filenames -iso-level 4

## Name of cookies
BASE_COOKIE=		${WRKDIR}/.base-done
BASEDIR_COOKIE=		${WRKDIR}/.basedir-done
BOOTSTRAP_COOKIE=	${WRKDIR}/.bootstrap-done
BOOTSTRAPDIR_COOKIE=	${WRKDIR}/.bootstrapdir-done
BOOTSTRAPSCRIPT_COOKIE=	${WRKDIR}/.bootstrapscript-done
COMPRESS_COOKIE=	${WRKDIR}/.compress-dir
CONFIG_COPY_COOKIE=	${WRKDIR}/.config_copy-done
FILES_COPY_COOKIE=	${WRKDIR}/.files_copy-done
KERNEL_COPY_COOKIE=	${WRKDIR}/.kernel_copy-done
KERNEL_EXTRACT_COOKIE=	${WRKDIR}/.kernel_extract-done
LOADER_COOKIE=		${WRKDIR}/.loader-done
LOADERBOOTSTRAP_COOKIE=	${WRKDIR}/.loader_bootstrap-done
PACKAGE_COOKIE=		${WRKDIR}/.package-done
PATCH_COOKIE=		${WRKDIR}/.patch-done
PORTS_COOKIE=		${WRKDIR}/.ports-done
SCRIPTS_COOKIE=		${WRKDIR}/.scripts-done
WRKDIR_COOKIE=		${WRKDIR}/.workdir-done
WORLD_EXTRACT_COOKIE=	${WRKDIR}/.world_extract-done
