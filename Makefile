# USER DEFINABLE VARIABLES

.if defined(CONFIG)
.	include	"${CONFIG}"
.endif

MDMFS_SIZE?=	32m
SCRIPTS?=	

## Kernel/world build options
SRCDIR?=	/usr/src
KERNCONF?=	GENERIC
TARGET?=	${UNAME_p}

## Working directories
UNAME_p!=	uname -p
. if ${TARGET} == ${UNAME_p}
WORKDIR?=	${PWD}/work
.else
WORKDIR?=	${PWD}/work/${TARGET}
.endif
BASEDIR?=	${WORKDIR}/base
BOOTSTRAPDIR?=	${WORKDIR}/bootstrap

## Source files
DISTFILES?=	${PWD}/distfiles
FILESRC?=	${PWD}/files
SCRIPTSDIR?=	${_MASTERSCRIPTSDIR}
_MASTERSCRIPTSDIR= ${.CURDIR}/scripts

.if ${TARGET} == ${UNAME_p}

PKGDIR?=	${DISTFILES}/packages

.  if ${KERNCONF} == GENERIC
KERNELSRC?=	${DISTFILES}/kernel.tar.bz2
.  else
KERNELSRC?=	${DISTFILES}/kernel-${KERNCONF}.tar.bz2
.  endif
PKG_ENV_DIR?=	/home/pkg_env
WORLDSRC?=	${DISTFILES}/world.tar.bz2

.else

PKGDIR?=	${DISTFILES}/packages-${TARGET}

.  if ${KERNCONF} == GENERIC
KERNELSRC?=	${DISTFILES}/kernel-${TARGET}.tar.bz2
.  else
KERNELSRC?=	${DISTFILES}/kernel-${KERNCONF}-${TARGET}.tar.bz2
.  endif
PKG_ENV_DIR?=	/home/pkg_env_${TARGET}
WORLDSRC?=	${DISTFILES}/world-${TARGET}.tar.bz2

.endif

PKGS?=
PORTS?=

## Bootstrap information
BOOTSTRAPDIRS+=		base boot dev overlay usr/lib
BOOTSTRAPFILES+=	etc/login.conf
BOOTSTRAPMODULES+=	zlib geom_uzip unionfs

## Target images
BASECOMPRESSEDIMAGE?=		${WORKDIR}/base.ufs.uzip
BOOTSTRAPCOMPRESSEDIMAGE?=	${WORKDIR}/bootstrap.ufs.gz
ISOFILE?=			${WORKDIR}/dragonbsd.iso
ISOMEMLIVEFILE?=		${WORKDIR}/dragonbsd-mem-live.iso
ISOLIVEFILE?=			${WORKDIR}/dragonbsd-live.iso
UFSFILE?=			${WORKDIR}/dragonbsd.ufs
UFSLIVEFILE?=			${WORKDIR}/dragonbsd-live.ufs
UFSMEMLIVEFILE?=		${WORKDIR}/dragonbsd-mem-live.ufs

## Sundry
MKISOFLAGS=	-quiet -sysid FREEBSD -rock -untranslated-filenames -max-iso9660-filenames -iso-level 4

## Name of cookies
BASE_COOKIE=		${WORKDIR}/.base-done
BASEDIR_COOKIE=		${WORKDIR}/.basedir-done
BOOTSTRAP_COOKIE=	${WORKDIR}/.bootstrap-done
BOOTSTRAPDIR_COOKIE=	${WORKDIR}/.bootstrapdir-done
BOOTSTRAPSCRIPT_COOKIE=	${WORKDIR}/.bootstrapscript-done
COMPRESS_COOKIE=	${WORKDIR}/.compress-dir
CONFIG_COPY_COOKIE=	${WORKDIR}/.config_copy-done
FILES_COPY_COOKIE=	${WORKDIR}/.files_copy-done
KERNEL_COPY_COOKIE=	${WORKDIR}/.kernel_copy-done
KERNEL_EXTRACT_COOKIE=	${WORKDIR}/.kernel_extract-done
LOADER_COOKIE=		${WORKDIR}/.loader-done
LOADERBOOTSTRAP_COOKIE=	${WORKDIR}/.loader_bootstrap-done
PACKAGE_COOKIE=		${WORKDIR}/.package-done
PATCH_COOKIE=		${WORKDIR}/.patch-done
PORTS_COOKIE=		${WORKDIR}/.ports-done
SCRIPTS_COOKIE=		${WORKDIR}/.scripts-done
WORKDIR_COOKIE=		${WORKDIR}/.workdir-done
WORLD_EXTRACT_COOKIE=	${WORKDIR}/.world_extract-done

#.SILENT:
.ORDER: ${ISOFILE} ${UFSFILE}
.ORDER: ${ISOLIVEEFILE} ${UFSLIVEFILE} ${ISOFILE}
.ORDER: partition_usb copy_ufs

.PHONY: usage help all live clean iso iso-live ufs ufs-live usb usb-live partition_usb copy_ufs

usage:
	@echo "usage: make [targets]"

help: usage
	@echo
	@echo "Creates an image file containing a full FreeBSD distribution.  The image format"
	@echo "can be specified ('ISO' for CD/DVD or 'UFS' for mass storage).  The type of"
	@echo "bootable system can also be specified ('normal' or 'live')."
	@echo
	@echo "Multiple targets
	@echo
	@echo "The following targets are available:"
	@echo "Types:"
	@echo "	iso		Creates a ISO image"
	@echo "	iso-live	Creates a live ISO image"
	@echo "	ufs		Creates a UFS image"
	@echo "	ufs-live	Creates a live UFS image"
	@echo
	@echo "Composites:"
	@echo "	all		Creates all the types above"
	@echo "	live		Creates all the live types above"
	@echo
	@echo "Utilities:"
	@echo "	clean		Remove all working files
	@echo "	usb		Writes a UFS image to a (USB) mass storage device*"
	@echo "	usb-live	Writes a live UFS image to a (USB) mass storage device*"
	@echo "*the device to write to must be specified using DEV (eg make usb DEV=/dev/da0)"
	@echo
	@echo "Help:"
	@echo "	help		Displays this help message"
	@echo "	help-[type]	Displays discription for [type] image (from above) [TODO]"
	@echo "	help-config	Displays information for customising a system image [TODO]"
	@echo
	@echo "???For further help see the manual pages (eg man dragonbsd) [TODO]"

all: iso iso-live ufs ufs-live

live: iso-live ufs-live

clean:
	@echo "===> Cleaning working area..."
	[ -z "`mount | grep ${BASEDIR}`" ] || umount `mount | grep ${BASEDIR} | cut -f 3 -d ' ' | sort -r`
	-rm -rf ${WORKDIR} 2> /dev/null || (chflags -R 0 ${WORKDIR}; rm -rf ${WORKDIR})

iso: ${ISOFILE}
	@echo "=== Created ISO image: ${ISOFILE} ==="

iso-live: ${ISOLIVEFILE}
	@echo "=== Created live ISO image: ${ISOLIVEFILE} ==="

ufs: ${UFSFILE}
	@echo "=== Created UFS image: ${UFSFILE} ==="

ufs-live: ${UFSLIVEFILE}
	@echo "=== Created live UFS image: ${UFSLIVEFILE} ==="

cd-live:
	@[ -n "${DEV}" ] || (echo "Please specify a device using make cd-live DEV=..."; echo "Possible devices:"; cdrecord -scanbus; false)
	#@[ -c ${DEV} ] || (echo "Please specify a valid character device"; false)
	@echo "===> Writing ISO image to ${DEV}"
	make burn_iso DEV=${DEV} IMAGEFILE=${ISOLIVEFILE}

usb:
	@[ -n "${DEV}" ] || (echo "Please specify a device using make ufs DEV=..."; false)
	@[ -c ${DEV} ] || (echo "Please specify a valid character device"; false)
	@echo "===> Writing UFS image to ${DEV}"
	make partition_usb copy_ufs DEV=${DEV} IMAGEFILE=${UFSFILE}


usb-live:
	@[ -n "${DEV}" ] || (echo "Please specify a device using make ufs-live DEV=..."; false)
	@[ -c ${DEV} ] || (echo "Please specify a valid character device"; false)
	@echo "===> Writing live UFS image to ${DEV}"
	make partition_usb copy_ufs DEV=${DEV} IMAGEFILE=${UFSLIVEFILE}

${WORKDIR_COOKIE}:
	@echo "===> Making working directory"
	mkdir -p ${WORKDIR}
	chown root:wheel ${WORKDIR}

	mkdir -p ${DISTFILES} ${PKGDIR}

	@touch ${WORKDIR_COOKIE}

${BASEDIR_COOKIE}: ${WORKDIR_COOKIE}
	@echo "===> Making base directory"
	mkdir -p ${BASEDIR}

	@touch ${BASEDIR_COOKIE}

${BASE_COOKIE}: ${CONFIG_COPY_COOKIE} ${PORTS_COOKIE} ${SCRIPTS_COOKIE}
	@touch ${BASE_COOKIE}

${BOOTSTRAP_COOKIE}: ${BOOTSTRAPSCRIPT_COOKIE} ${COMPRESS_COOKIE}
	@touch ${BOOTSTRAP_COOKIE}

${WORLDSRC}:
	@echo "===> Building world from source..."
	make -C ${SRCDIR} -j`sysctl -n hw.ncpu` buildworld TARGET=${TARGET}
	WORLDTMP=`mktemp -d /tmp/world.XXXXXX` && \
	make -C ${SRCDIR} installworld distribution DESTDIR=$${WORLDTMP} TARGET=${TARGET} && \
	tar -C $${WORLDTMP} -cjf ${WORLDSRC} . && \
	(rm -rf $${WORLDTMP} || (chflags -R 0 $${WORLDTMP}; rm -rf $${WORLDTMP}))


# Extract the world (aka `make installworld distribution`)
# Compensate for x86 support in amd64 distributions
${WORLD_EXTRACT_COOKIE}: ${WORLDSRC} ${BASEDIR_COOKIE}
	@echo "===> Extracting userland files..."
	tar -C ${BASEDIR} -xf ${WORLDSRC}
	-ln -s ld-elf.so.1 ${BASEDIR}/libexec/ld-elf32.so.1

	@touch ${WORLD_EXTRACT_COOKIE}

${KERNELSRC}:
	@echo "===> Building kernel from source..."
	make -C ${SRCDIR} -j`sysctl -n hw.ncpu` kernel-toolchain buildkernel KERNCONF=${KERNCONF} TARGET=${TARGET}
	KERNELTMP=`mktemp -d /tmp/kernel.XXXXXX` && \
	make -C ${SRCDIR} installkernel DESTDIR=$${KERNELTMP} KERNCONF=${KERNCONF} TARGET=${TARGET} && \
	tar -C $${KERNELTMP} -cjf ${KERNELSRC} . && \
	(rm -rf $${KERNELTMP} || (chflags -R 0 $${KERNELTMP}; rm -rf $${KERNELTMP}))

# Extract the kernel (aka `make installkernel`)
${KERNEL_EXTRACT_COOKIE}: ${KERNELSRC} ${BASEDIR_COOKIE}
	@echo "===> Extracting kernel files..."
	tar -C ${BASEDIR} -xf ${KERNELSRC}

	@touch ${KERNEL_EXTRACT_COOKIE}

# Copy across user files (configuration files and others)
${CONFIG_COPY_COOKIE}: ${WORLD_EXTRACT_COOKIE} ${KERNEL_EXTRACT_COOKIE}
	@echo "===> Copying across user files..."
	touch ${BASEDIR}/boot/loader.conf
	tar -C ${FILESRC} -cf - . | tar -C ${BASEDIR} -xf -

	@touch ${CONFIG_COPY_COOKIE}

# Prepare all directories required for bootstrapping
${BOOTSTRAPDIR_COOKIE}: ${CONFIG_COPY_COOKIE}
	@echo "===> Creating directories for bootstrap"
	mkdir -p ${BOOTSTRAPDIR}
	(cd ${BOOTSTRAPDIR}; mkdir -p ${BOOTSTRAPDIRS} `cd ${BASEDIR}; find boot -type d -depth 1`)

	@touch ${BOOTSTRAPDIR_COOKIE}

# Copy across all userland files required for bootstrapping
${FILES_COPY_COOKIE}: ${BOOTSTRAPDIR_COOKIE} ${CONFIG_COPY_COOKIE}
	@echo "===> Copying userland files for bootstrap"
	tar -C ${BASEDIR} -cf - rescue ${BOOTSTRAPFILES} | \
		tar -C ${BOOTSTRAPDIR} -xf -

	@touch ${FILES_COPY_COOKIE}

# Copy across all loader/kernel files required for bootstrapping
${LOADER_COOKIE}: ${FILES_COPY_COOKIE} ${BOOTSTRAPDIR_COOKIE}
	@echo "===> Copying loader/kernel files for bootstrap"
	(cd ${BASEDIR}; \
	  tar -cf - `find boot -type f -depth 1`) | tar -C ${BOOTSTRAPDIR} -xf -

	-(tar -C ${BASEDIR} -cf - boot/defaults | tar -C ${BOOTSTRAPDIR} -xf -) 2> /dev/null
	-cp -fp ${BASEDIR}/usr/lib/kgzldr.o ${BOOTSTRAPDIR}/usr/lib 2> /dev/null

	@touch ${LOADER_COOKIE}

# Patch the loader.conf file for bootstrapping
${PATCH_COOKIE}: ${LOADER_COOKIE}
	@echo "===> Patching the loader.conf for bootstrap"
	echo >> ${BOOTSTRAPDIR}/boot/loader.conf

	for module in ${BOOTSTRAPMODULES}; \
	do \
		if [ -z "`grep ^$${module}_load=\"[Yy][Ee][Ss]\".\* ${BOOTSTRAPDIR}/boot/loader.conf`" ]; \
		then \
			echo "$${module}_load=\"YES\"" >> ${BOOTSTRAPDIR}/boot/loader.conf; \
		fi \
	done

	echo init_script=\"/chroot\" >> ${BOOTSTRAPDIR}/boot/loader.conf
	echo init_chroot=\"/base\" >> ${BOOTSTRAPDIR}/boot/loader.conf

	@touch ${PATCH_COOKIE}

# Copy across all kernel objects required for bootstrap
${KERNEL_COPY_COOKIE}: ${PATCH_COOKIE}
	@echo "===> Copying kernel for bootstrap"
	cp -fp ${BASEDIR}/boot/kernel/kernel ${BOOTSTRAPDIR}/boot/kernel

	-cp -fp ${BASEDIR}/boot/kernel/acpi.ko ${BOOTSTRAPDIR}/boot/kernel 2> /dev/null

	for module in `grep '[0-9A-Za-z_]_load="[Yy][Ee][Ss]".*' ${BOOTSTRAPDIR}/boot/loader.conf | sed 's|_load="[Yy][Ee][Ss]".*||g' `; \
	do \
		[ ! -f ${BASEDIR}/boot/kernel/$${module}.ko ] || cp -p ${BASEDIR}/boot/kernel/$${module}.ko ${BOOTSTRAPDIR}/boot/kernel; \
		[ ! -f ${BASEDIR}/boot/modules/$${module}.ko ] || cp -p ${BASEDIR}/boot/modules/$${module}.ko ${BOOTSTRAPDIR}/boot/modules; \
	done

	@touch ${KERNEL_COPY_COOKIE}

# Compress kernel objects
${COMPRESS_COOKIE}: ${KERNEL_COPY_COOKIE}
	@echo "===> Compressing the kernel"
	gzip -f9 `find ${BOOTSTRAPDIR}/boot/kernel/ -type f` `find ${BOOTSTRAPDIR}/boot/modules/ -type f`

	@touch ${COMPRESS_COOKIE}

# Write the bootstrap scripts
${BOOTSTRAPSCRIPT_COOKIE}: ${BOOTSTRAPDIR_COOKIE}
	@echo "===> Writing the bootstrap script"
	echo '#!/rescue/sh \
^PATH=/rescue \
^trap "@echo Recovery console: ; PATH=/rescue /rescue/csh -i ; exit" 1 2 3 6 15 \
^\
^if [ -f /base.ufs.uzip ] \
^then \
^  echo "Mounting compressed base:" \
^  mount -o ro /dev/$$(mdconfig -a -t vnode -o readonly -f /base.ufs.uzip).uzip /base \
^else \
^  echo "Mounting base:" \
^  mount -o ro /dev/$$(mdconfig -a -t vnode -o readonly -f /base.ufs) /base \
^fi \
^\
^if [ -w /dev/ufs/DragonBSDUFS ] \
^then \
^  echo -n "Overlaying filesystem:" \
^  mount /dev/ufs/DragonBSDUFS /overlay \
^else \
^  echo -n "Allocating temporary filesystem (${MDMFS_SIZE}):" \
^  mdmfs -s ${MDMFS_SIZE} md /overlay \
^  echo . \
^  \
^  echo -n "Overlaying temporary filesystem:" \
^fi \
^mount -t unionfs -o noatime -o copymode=transparent /overlay /base \
^echo . \
^\
^mount -t devfs devfs /base/dev \
^\
^echo "Patching /etc/rc.conf" \
^if [ ! -f /base/etc/rc.conf ] \
^then \
^  echo "root_rw_mount=\"NO\"" > /base/etc/rc.conf \
^else \
^  case $$(cat /base/etc/rc.conf) in \
^    *root_rw_mount=*) \
^      ;; \
^    *) \
^      echo >> /base/etc/rc.conf \
^      echo "root_rw_mount=\"NO\"" >> /base/etc/rc.conf \
^      ;; \
^  esac \
^fi \
^\
^CD_DEV=$$(dmesg | sed -n -e "s|.* a\(cd[0-9]\+\) .*iso9660/DragonBSDMEMLive.*|\1|p" | sed "1 q") \
^if [ -n "$$CD_DEV" ] \
^then \
^  echo "Ejecting CD-ROM..." \
^  if [ -f /base/boot/kernel/atapicam.ko -a -z "$$(kldstat -v | grep ata/atapicam)" ] \
^  then \
^    kldload /base/boot/kernel/atapicam.ko \
^  fi \
^  camcontrol eject $$CD_DEV \
^fi \
^\
^echo "Chroot to base..."' | tr '^' '\n' > ${BOOTSTRAPDIR}/chroot
	chmod a+x ${BOOTSTRAPDIR}/chroot

	@touch ${BOOTSTRAPSCRIPT_COOKIE}

${BASECOMPRESSEDIMAGE}: ${UFSFILE}
	@echo "===> Compressing UFS Image of filesystem..."
	mkuzip -s 8192 -o ${BASECOMPRESSEDIMAGE} ${UFSFILE}

.ORDER: ${BOOTSTRAP_COOKIE} ${ISOLIVEFILE} ${UFSLIVEFILE} ${BOOTSTRAPCOMPRESSEDIMAGE} ${LOADERBOOTSTRAP_COOKIE}

${BOOTSTRAPCOMPRESSEDIMAGE}: ${BOOTSTRAP_COOKIE} ${BASECOMPRESSEDIMAGE}
	@echo "===> Compressing bootstrap UFS Image..."
	mv ${BOOTSTRAPDIR}/boot ${WORKDIR}/

	ln ${BASECOMPRESSEDIMAGE} ${BOOTSTRAPDIR}/base.ufs.uzip

	makefs ${BOOTSTRAPCOMPRESSEDIMAGE} ${BOOTSTRAPDIR} \
	  || (mv ${WORKDIR}/boot ${BOOTSTRAPDIR}/; rm ${BOOTSTRAPDIR}/base.ufs.uzip; false)
	tunefs -L DragonBSDMEM ${BOOTSTRAPCOMPRESSEDIMAGE}
	gzip -9 ${BOOTSTRAPCOMPRESSEDIMAGE}
	mv ${BOOTSTRAPCOMPRESSEDIMAGE}.gz ${BOOTSTRAPCOMPRESSEDIMAGE}

	mv ${WORKDIR}/boot ${BOOTSTRAPDIR}/
	rm ${BOOTSTRAPDIR}/base.ufs.uzip

${LOADERBOOTSTRAP_COOKIE}: ${BOOTSTRAP_COOKIE}
	@echo "===> Creating loader environment for compressed bootstrap image..."
	mkdir -p ${LOADERBOOTSTRAPDIR} ${LOADERBOOTSTRAPDIR}/usr/lib

	-(tar -C ${BOOTSTRAPDIR} -cf - boot | tar -C ${LOADERBOOTSTRAPDIR} -xf -)
	-cp -fp ${BOOTSTRAPDIR}/usr/lib/kgzldr.o ${LOADERBOOTSTRAPDIR}/usr/lib 2> /dev/null

	@touch ${LOADERBOOTSTRAP_COOKIE}

.ORDER: ${ISOMEMLIVEFILE} ${UFSMEMLIVEFILE}

${ISOMEMLIVEFILE}: ${BOOTSTRAPCOMPRESSEDIMAGE} ${LOADERBOOTSTRAP_COOKIE}
	@echo "===> Creating Memory based Live ISO image"
	cp -p ${LOADERBOOTSTRAPDIR}/boot/loader.conf ${WORKDIR}/
	echo >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	echo "rootimg_load=\"YES\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	echo "rootimg_type=\"mfs_root\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	echo "rootimg_name=\"/boot/kernel/bootstrap.ufs\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	echo "vfs.root.mountfrom=\"ufs:/dev/ufs/DragonBSDMEM\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf

	ln ${BASECOMPRESSEDIMAGE} ${LOADERBOOTSTRAPDIR}/boot/kernel/bootstrap.ufs.gz

	mkisofs ${MKISOFLAGS}  -b boot/cdboot --no-emul-boot -volid DragonBSDMEMLive -o ${ISOMEMLIVEFILE} ${LOADERBOOTSTRAPDIR} \
	  || (mv ${WORKDIR}/loader.conf ${LOADERBOOTSTRAPDIR}/boot/; rm ${LOADERBOOTSTRAPDIR}/boot/kernel/bootstrap.ufs.gz; false)

	mv ${WORKDIR}/loader.conf ${LOADERBOOTSTRAPDIR}/boot/
	rm ${LOADERBOOTSTRAPDIR}/boot/kernel/bootstrap.ufs.gz

${UFSMEMLIVEFILE}: ${BOOTSTRAPCOMPRESSEDIMAGE} ${LOADERBOOTSTRAP_COOKIE}
	@echo "===> Creating Memory based Live UFS image"
	cp -p ${LOADERBOOTSTRAPDIR}/boot/loader.conf ${WORKDIR}/
	echo >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	echo "rootimg_load=\"YES\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	echo "rootimg_type=\"mfs_root\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	echo "rootimg_name=\"/boot/kernel/bootstrap.ufs\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	echo "vfs.root.mountfrom=\"ufs:/dev/ufs/DragonBSDMEM\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf

	ln ${BASECOMPRESSEDIMAGE} ${LOADERBOOTSTRAPDIR}/boot/kernel/bootstrap.ufs.gz

	makefs ${UFSMEMLIVEFILE} ${LOADERBOOTSTRAPDIR} \
	  || (mv ${WORKDIR}/loader.conf ${LOADERBOOTSTRAPDIR}/boot/; rm ${LOADERBOOTSTRAPDIR}/boot/kernel/bootstrap.ufs.gz; false)
	tunefs -L DragonBSDMEMLive ${UFSLIVEFILE}

	mv ${WORKDIR}/loader.conf ${LOADERBOOTSTRAPDIR}/boot/
	rm ${LOADERBOOTSTRAPDIR}/boot/kernel/bootstrap.ufs.gz

${PACKAGE_COOKIE}: ${WORLD_EXTRACT_COOKIE}
	@echo "===> Installing packages..."
	[ -z "`mount | grep ${BASEDIR}`" ] || umount `mount | grep ${BASEDIR} | cut -f 3 -d ' ' | sort -r`
	mount -t devfs devfs ${BASEDIR}/dev
	mount -t nullfs ${PKGDIR} ${BASEDIR}/mnt
	for PKG in ${PKGS}; \
	do \
		pkgs=`cd ${BASEDIR}/mnt/All; ls $${PKG}*t[bg]z 2> /dev/null || true`; \
		if [ -n "$${pkgs}" ]; \
		then \
			echo "==> Installing packages: $${pkgs}"; \
			chroot ${BASEDIR} sh -c "cd /mnt/All && pkg_add -F $${pkgs}" || \
			  (umount ${BASEDIR}/dev ${BASEDIR}/mnt; false); \
		else \
			echo "==> No packages with name ${PKG}"; \
		fi; \
	done
	umount ${BASEDIR}/dev ${BASEDIR}/mnt

	@touch ${PACKAGE_COOKIE}

_MOUNTDIRS=${BASEDIR}/tmp ${BASEDIR}/dev ${BASEDIR}/usr/freebsd ${BASEDIR}/usr/ports #${BASEDIR}/usr/ports/packages ${BASEDIR}/usr/freebsd/packages

${PORTS_COOKIE}: ${PACKAGE_COOKIE}
	@echo "===> Installing ports..."
	[ -z "`mount | grep ${BASEDIR}`" ] || umount `mount | grep ${BASEDIR} | cut -f 3 -d ' ' | sort -r`
	mkdir -p ${BASEDIR}/usr/ports ${BASEDIR}/usr/ports/packages ${BASEDIR}/usr/freebsd
	mount -t nullfs /usr/ports ${BASEDIR}/usr/ports
	mount -t nullfs /usr/freebsd ${BASEDIR}/usr/freebsd
	mount -t devfs devfs ${BASEDIR}/dev
	mount -t tmpfs tmpfs ${BASEDIR}/tmp
	#mount -t nullfs ${PKGDIR} ${BASEDIR}/usr/freebsd/packages
	#mount -t nullfs ${PKGDIR} ${BASEDIR}/usr/ports/packages

	for PORT in ${PORTS}; \
	do \
		if [ -d ${BASEDIR}/usr/ports/$${PORT} ]; \
		then \
			pkg=`chroot ${BASEDIR} make -C /usr/ports/$${PORT} package-name`; \
			if [ ! -f "`echo ${BASEDIR}/usr/ports/packages/All/$${pkg}.t[bg]z`" ]; \
			then \
				echo "==> Building port: $${PORT}"; \
				chroot ${BASEDIR} make -C /usr/ports/$${PORT} install package-recursive clean BATCH=yes DEPENDS_CLEAN=yes NOCLEANDEPENDS=yes || \
				  (umount ${_MOUNTDIRS}; false); \
			else \
				echo "==> Installing port: $${PORT} ($${pkg})"; \
				chroot ${BASEDIR} sh -c "cd /usr/ports/packages/All && pkg_add -F $${pkg}.t[bg]z" || \
				  (umount ${_MOUNTDIRS}; false); \
			fi; \
		else \
			echo "==> No port with name $${PORT}"; \
		fi; \
	done

	umount ${_MOUNTDIRS}

	@touch ${PORTS_COOKIE}

${SCRIPTS_COOKIE}: ${PORTS_COOKIE}
	@echo "===> Running customising scripts..."
.for script in ${SCRIPTS}
.if ${SCRIPTSDIR} != ${_MASTERSCRIPTSDIR}
	if [ -x ${SCRIPTSDIR}/${script} ]; then \
		env BASEDIR=${BASEDIR} CONFIG=${CONFIG} ${SCRIPTSDIR}/${script}; \
	else \
		env BASEDIR=${BASEDIR} CONFIG=${CONFIG} ${_MASTERSCRIPTSDIR}/${script}; \
	fi
.else
	env BASEDIR=${BASEDIR} CONFIG=${CONFIG} ${SCRIPTSDIR}/${script}
.endif
.endfor

	@touch ${SCRIPTS_COOKIE}

# Create an ISO image (from the base image)
${ISOFILE}: ${BASE_COOKIE}
	@echo "===> Creating ISO image"
	cp -p ${BASEDIR}/boot/loader.conf ${WORKDIR}/
	cp -p ${BASEDIR}/etc/rc.conf ${WORKDIR}/
	echo >> ${BASEDIR}/boot/loader.conf
	echo "vfs.root.mountfrom=\"cd9660:/dev/iso9660/DragonBSD\"" >> ${BASEDIR}/boot/loader.conf
	if [ -z "`grep root_rw_mount= ${BASEDIR}/etc/rc.conf`" ]; then \
		echo >> ${BASEDIR}/etc/rc.conf; \
		echo 'root_rw_mount="NO"' >> ${BASEDIR}/etc/rc.conf; \
	fi

	mkisofs ${MKISOFLAGS}  -b boot/cdboot --no-emul-boot -volid DragonBSD -o ${ISOFILE} ${BASEDIR} \
          || (mv ${WORKDIR}/rc.conf ${BASEDIR}/etc/; mv ${WORKDIR}/loader.conf ${BASEDIR}/boot/; false)

	mv ${WORKDIR}/rc.conf ${BASEDIR}/etc/
	mv ${WORKDIR}/loader.conf ${BASEDIR}/boot/

# Create an ISO image with editable filesystem (live)
${ISOLIVEFILE}: ${BOOTSTRAP_COOKIE} ${BASECOMPRESSEDIMAGE}
	@echo "===> Creating Live ISO image"
	cp -p ${BOOTSTRAPDIR}/boot/loader.conf ${WORKDIR}/
	echo >> ${BOOTSTRAPDIR}/boot/loader.conf
	echo "vfs.root.mountfrom=\"cd9660:/dev/iso9660/DragonBSDLive\"" >> ${BOOTSTRAPDIR}/boot/loader.conf

	ln ${BASECOMPRESSEDIMAGE} ${BOOTSTRAPDIR}/base.ufs.uzip

	mkisofs ${MKISOFLAGS}  -b boot/cdboot --no-emul-boot -volid DragonBSDLive -o ${ISOLIVEFILE} ${BOOTSTRAPDIR} \
	  || (mv ${WORKDIR}/loader.conf ${BOOTSTRAPDIR}/boot/; rm ${BOOTSTRAPDIR}/base.ufs.uzip; false)

	mv ${WORKDIR}/loader.conf ${BOOTSTRAPDIR}/boot/
	rm ${BOOTSTRAPDIR}/base.ufs.uzip

# Create an UFS image (from the base image)
${UFSFILE}: ${BASE_COOKIE}
	@echo "===> Creating UFS Image"
	cp -p ${BASEDIR}/boot/loader.conf ${WORKDIR}/
	echo >> ${BASEDIR}/boot/loader.conf
	echo "vfs.root.mountfrom=\"ufs:/dev/ufs/DragonBSD\"" >> ${BASEDIR}/boot/loader.conf

	makefs ${UFSFILE} ${BASEDIR} \
	  || (mv ${WORKDIR}/loader.conf ${BASEDIR}/boot/; false)
	tunefs -L DragonBSD ${UFSFILE}

	mv ${WORKDIR}/loader.conf ${BASEDIR}/boot/

${UFSLIVEFILE}: ${BOOTSTRAP_COOKIE} ${BASECOMPRESSEDIMAGE}
	@echo "===> Creating Live UFS image"
	cp -p ${BOOTSTRAPDIR}/boot/loader.conf ${WORKDIR}/
	echo >> ${BOOTSTRAPDIR}/boot/loader.conf
	echo "vfs.root.mountfrom=\"ufs:/dev/ufs/DragonBSDLive\"" >> ${BOOTSTRAPDIR}/boot/loader.conf

	ln ${BASECOMPRESSEDIMAGE} ${BOOTSTRAPDIR}/base.ufs.uzip

	makefs ${UFSLIVEFILE} ${BOOTSTRAPDIR} \
	  || (mv ${WORKDIR}/loader.conf ${BOOTSTRAPDIR}/boot/; rm ${BOOTSTRAPDIR}/base.ufs.uzip; false)
	tunefs -L DragonBSDLive ${UFSLIVEFILE}

	mv ${WORKDIR}/loader.conf ${BOOTSTRAPDIR}/boot/
	rm ${BOOTSTRAPDIR}/base.ufs.uzip

partition_usb: ${IMAGEFILE}
	@echo "===> Partitioning device ${DEV}"
	fdisk -BI ${DEV}
	bsdlabel -Bwb ${BASEDIR}/boot/boot ${DEV}s1
	echo "8 partitions: \
^a: `du -Ak ${IMAGEFILE} | cut -f 1`k * 4.2BSD \
^b: * * 4.2BSD \
^c: * * unused" | tr '^' '\n' >> ${WORKDIR}/bsdlabel
	bsdlabel -R ${DEV}s1 ${WORKDIR}/bsdlabel
	rm ${WORKDIR}/bsdlabel
	newfs -EUL DragonBSDUFS ${DEV}s1b

copy_ufs: ${IMAGEFILE}
	@echo "===> Copying UFS image to device ${DEV}..."
	dd if=${IMAGEFILE} of=${DEV}s1a bs=64k

burn_iso: ${IMAGEFILE}
	@echo "===> Burning ISO image to device ${DEV}..."
	cdrecord blank=fast dev=${DEV} -eject -data ${IMAGEFILE}
	#burncd -e -f ${DEV} -s max blank data ${IMAGEFILE} fixate
