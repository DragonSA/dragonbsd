# USER DEFINABLE VARIABLES

.if defined(NAME)
.	if defined(NAMECONF)
.		${NAMECONF}
.	else
.		${NAME}
.	endif
.endif

## Kernel/world build options
SRCDIR?=	/usr/src
KERNCONF?=	GENERIC
TARGET?=	`uname -p`

## Working directories
WORKDIR?=	${PWD}/work
BASEDIR?=	${WORKDIR}/base
BOOTSTRAPDIR?=	${WORKDIR}/bootstrap

## Source files
DISTFILES?=	${PWD}/distfiles
KERNELSRC?=	${DISTFILES}/kernel.tar.bz2
FILESRC?=	${PWD}/files
WORLDSRC?=	${DISTFILES}/world.tar.bz2
PKGDIR?=	${DISTFILES}/packages

PKGS?=
PORTS?=

## Bootstrap information
BOOTSTRAPDIRS+=		base boot dev overlay usr/lib
BOOTSTRAPFILES+=	etc/login.conf
BOOTSTRAPMODULES+=	geom_uzip unionfs zlib

## Target images
BASECOMPRESSEDIMAGE?=	${WORKDIR}/base.ufs.uzip
ISOFILE?=		${WORKDIR}/dragonbsd.iso
ISOLIVEFILE?=		${WORKDIR}/dragonbsd-live.iso
UFSFILE?=		${WORKDIR}/dragonbsd.ufs
UFSLIVEFILE?=		${WORKDIR}/dragonbsd-live.ufs

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
PACKAGE_COOKIE=		${WORKDIR}/.package-done
PATCH_COOKIE=		${WORKDIR}/.patch-done
PORTS_COOKIE=		${WORKDIR}/.ports-done
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

usb:
	@[ -n "${DEV}" ] || (echo "Please specify a device using make ufs DEV=..."; false)
	@[ -c ${DEV} ] || (echo "Please specify a valid character device"; false)
	@echo "===> Writing UFS image to ${DEV}"
	make partition_usb copy_ufs DEV=${DEV} IMAGEFILE=${UFSFILE} BASENAME=DragonBSD SUPPNAME=DragonBSD2


usb-live:
	@[ -n "${DEV}" ] || (echo "Please specify a device using make ufs DEV=..."; false)
	@[ -c ${DEV} ] || (echo "Please specify a valid character device"; false)
	@echo "===> Writing live UFS image to ${DEV}"
	make partition_usb copy_ufs DEV=${DEV} IMAGEFILE=${UFSLIVEFILE} BASENAME=DragonBSDBase SUPPNAME=DragonBSD

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

${BASE_COOKIE}: ${CONFIG_COPY_COOKIE} ${PORTS_COOKIE}
	@touch ${BASE_COOKIE}

${BOOTSTRAP_COOKIE}: ${BOOTSTRAPSCRIPT_COOKIE} ${COMPRESS_COOKIE}
	@touch ${BOOTSTRAP_COOKIE}

${WORLDSRC}:
	@echo "===> Building world from source..."
	make -C ${SRCDIR} -j`sysctl -n hw.ncpu` buildworld TARGET=${TARGET}
	WORLDDIR=`mktemp -d /tmp/world.XXXXXX` && \
	make -C ${SRCDIR} installworld distribution DESTDIR=$$WORLDDIR TARGET=${TARGET} && \
	tar -C $$WORLDDIR -cjf ${WORLDSRC} . && \
	(rm -rf $$WORLDDIR || (chflags -R 0 $$WORLDDIR ; rm -rf $$WORLDDIR))

# Extract the world (aka `make installworld distribution`)
# Compensate for x86 support in amd64 distributions
${WORLD_EXTRACT_COOKIE}: ${WORLDSRC} ${BASEDIR_COOKIE}
	@echo "===> Extracting userland files..."
	tar -C ${BASEDIR} -xf ${WORLDSRC}
	-(cd ${BASEDIR}/libexec; ln -s ld-elf.so.1 ld-elf32.so.1)

	@touch ${WORLD_EXTRACT_COOKIE}

${KERNELSRC}:
	@echo "===> Building kernel from source..."
	make -C ${SRCDIR} -j`sysctl -n hw.ncpu` kernel-toolchain buildkernel KERNCONF=${KERNCONF} TARGET=${TARGET}
	KERNELDIR=`mktemp -d /tmp/kernel.XXXXXX` && \
	make -C ${SRCDIR} installkernel DESTDIR=$$KERNELDIR KERNCONF=${KERNCONF} TARGET=${TARGET} && \
	tar -C $$KERNELDIR -cjf ${KERNELSRC} . && \
	(rm -rf $$KERNELDIR || (chflags -R 0 $$KERNELDIR ; rm -rf $$KERNELDIR))

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
	#gzip -f9 `find ${BOOTSTRAPDIR}/boot/kernel/ -type f` `find ${BOOTSTRAPDIR}/boot/modules/ -type f`

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
^if [ -w /dev/ufs/DragonBSD ] \
^then \
^  echo "Overlaying filesystem:" \
^  mount /dev/ufs/DragonBSD /overlay \
^else \
^  echo "Allocating temporary filesystem (32m):" \
^  mdmfs -s 32m md /overlay \
^  \
^  echo "Overlaying temporary filesystem:" \
^fi \
^mount -t unionfs -o noatime -o copymode=transparent /overlay /base \
^\
^mount -t devfs devfs /base/dev \
^\
^echo "Chroot to base..."' | tr '^' '\n' > ${BOOTSTRAPDIR}/chroot
	chmod a+x ${BOOTSTRAPDIR}/chroot

	@touch ${BOOTSTRAPSCRIPT_COOKIE}

${BASECOMPRESSEDIMAGE}: ${UFSFILE}
	@echo "===> Compressing UFS Image of filesystem..."
	mkuzip -s 8192 -o ${BASECOMPRESSEDIMAGE} ${UFSFILE}

${PACKAGE_COOKIE}: ${WORLD_EXTRACT_COOKIE}
	@echo "===> Installing packages..."
	[ -z "`mount | grep ${BASEDIR}`" ] || umount `mount | grep ${BASEDIR} | cut -f 3 -d ' ' | sort -r`
	mount -t devfs devfs ${BASEDIR}/dev
	mount -t nullfs ${PKGDIR} ${BASEDIR}/mnt
	for PKG in ${PKGS}; \
	do \
		pkgs=`cd ${BASEDIR}/mnt; echo $${PKG}*t[bg]z`; \
		if [ -n "$${pkgs}" ]; \
		then \
			echo "==> Installing packages: $${pkgs}"; \
			chroot ${BASEDIR} sh -c "cd /mnt && pkg_add -F $${pkgs}" || \
			  (umount ${BASEDIR}/dev ${BASEDIR}/mnt; false); \
		else \
			echo "==> No packages with name ${PKG}"; \
		fi; \
	done
	umount ${BASEDIR}/dev ${BASEDIR}/mnt

	touch ${PACKAGE_COOKIE}

MOUNTDIRS=${BASEDIR}/tmp ${BASEDIR}/dev ${BASEDIR}/usr/freebsd ${BASEDIR}/usr/ports #${BASEDIR}/usr/ports/packages ${BASEDIR}/usr/freebsd/packages

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
	-(cd ${BASEDIR}/usr/ports/packages; ln -s . All)

	for PORT in ${PORTS}; \
	do \
		if [ -d ${BASEDIR}/usr/ports/$${PORT} ]; \
		then \
			pkg=`chroot ${BASEDIR} make -C /usr/ports/$${PORT} package-name`; \
			if [ ! -f "`echo ${BASEDIR}/usr/ports/packages/$${pkg}.t[bg]z`" ]; \
			then \
				echo "==> Building port: $${PORT}"; \
				chroot ${BASEDIR} make -C /usr/ports/$${PORT} install package-recursive clean BATCH=yes DEPENDS_CLEAN=yes NOCLEANDEPENDS=yes || \
				  (umount ${MOUNTDIRS}; false); \
			else \
				echo "==> Installing port: $${PORT} ($${pkg})"; \
				chroot ${BASEDIR} sh -c "cd /usr/ports/packages/All && pkg_add -F $${pkg}.t[bg]z" || \
				  (umount ${MOUNTDIRS}; false); \
			fi; \
		else \
			echo "==> No port with name $${PORT}"; \
		fi; \
	done

	umount ${MOUNTDIRS}

	touch ${PORTS_COOKIE}

# Create an ISO image (from the base image)
${ISOFILE}: ${BASE_COOKIE}
	@echo "===> Creating ISO image"
	cp -p ${BASEDIR}/boot/loader.conf ${WORKDIR}/
	echo >> ${BASEDIR}/boot/loader.conf
	echo "vfs.root.mountfrom=\"cd9660:/dev/iso9660/DragonBSD\"" >> ${BASEDIR}/boot/loader.conf

	mkisofs ${MKISOFLAGS}  -b boot/cdboot --no-emul-boot -volid DragonBSD -o ${ISOFILE} ${BASEDIR} \
          || (mv ${WORKDIR}/loader.conf ${BASEDIR}/boot/; false)

	mv ${WORKDIR}/loader.conf ${BASEDIR}/boot/

# Create an ISO image with editable filesystem (live)
${ISOLIVEFILE}: ${BOOTSTRAP_COOKIE} ${BASECOMPRESSEDIMAGE}
	@echo "===> Creating Live ISO image"
	cp -p ${BOOTSTRAPDIR}/boot/loader.conf ${WORKDIR}/
	echo >> ${BOOTSTRAPDIR}/boot/loader.conf
	echo "vfs.root.mountfrom=\"cd9660:/dev/iso9660/DragonBSD\"" >> ${BOOTSTRAPDIR}/boot/loader.conf

	ln ${BASECOMPRESSEDIMAGE} ${BOOTSTRAPDIR}/base.ufs.uzip

	mkisofs ${MKISOFLAGS}  -b boot/cdboot --no-emul-boot -volid DragonBSD -o ${ISOLIVEFILE} ${BOOTSTRAPDIR} \
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

	mv ${WORKDIR}/loader.conf ${BASEDIR}/boot/

${UFSLIVEFILE}: ${BOOTSTRAP_COOKIE} ${BASECOMPRESSEDIMAGE}
	@echo "===> Creating Live UFS image"
	cp -p ${BOOTSTRAPDIR}/boot/loader.conf ${WORKDIR}/
	echo >> ${BOOTSTRAPDIR}/boot/loader.conf
	echo "vfs.root.mountfrom=\"ufs:/dev/ufs/DragonBSDBase\"" >> ${BOOTSTRAPDIR}/boot/loader.conf

	ln ${BASECOMPRESSEDIMAGE} ${BOOTSTRAPDIR}/base.ufs.uzip

	makefs ${UFSLIVEFILE} ${BOOTSTRAPDIR} \
	  || (mv ${WORKDIR}/loader.conf ${BOOTSTRAPDIR}/boot/; rm ${BOOTSTRAPDIR}/base.ufs.uzip; false)

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
	newfs -EUL ${SUPPNAME} ${DEV}s1b

copy_ufs: ${IMAGEFILE}
	@echo "===> Copying (Live) UFS image to device ${DEV}..."
	dd if=${IMAGEFILE} of=${DEV}s1a bs=64k
	tunefs -L ${BASENAME} ${DEV}s1a
