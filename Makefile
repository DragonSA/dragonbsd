# USER DEFINABLE VARIABLES

.include "bsd.commands.mk"
.include "bsd.doc.mk"
.include "bsd.variables.mk"

.if defined(CONFIG)
.	include	"${CONFIG}"
.endif

#.SILENT:
.ORDER: ${ISOFILE} ${UFSFILE}
.ORDER: ${ISOLIVEEFILE} ${UFSLIVEFILE} ${ISOFILE}
.ORDER: partition_usb copy_ufs

.PHONY: usage help all live clean iso iso-live ufs ufs-live usb usb-live partition_usb copy_ufs

all: iso iso-live ufs ufs-live

live: iso-live ufs-live

memlive: iso-memlive ufs-memlive

clean:
	@${ECHO} "===> Cleaning working area..."
	[ -z "`${MOUNT} | ${GREP} ${BASEDIR}`" ] || ${UMOUNT} `${MOUNT} | ${GREP} ${BASEDIR} | ${CUT} -f 3 -d ' ' | ${SORT} -r`
	-${RM} -rf ${WRKDIR} 2> /dev/null || (${CHFLAGS} -R 0 ${WRKDIR}; ${RM} -rf ${WRKDIR})

iso: ${ISOFILE}
	@${ECHO} "=== Created ISO image: ${ISOFILE} ==="

iso-live: ${ISOLIVEFILE}
	@${ECHO} "=== Created live ISO image: ${ISOLIVEFILE} ==="

iso-memlive: ${ISOMEMLIVEFILE}
	@${ECHO} "=== Created live memory based ISO image: ${ISOMEMLIVEFILE} ==="

ufs: ${UFSFILE}
	@${ECHO} "=== Created UFS image: ${UFSFILE} ==="

ufs-live: ${UFSLIVEFILE}
	@${ECHO} "=== Created live UFS image: ${UFSLIVEFILE} ==="

ufs-memlive: ${UFSMEMLIVEFILE}
	@${ECHO} "=== Created live memory based UFS image: ${UFSMEMLIVEFILE} ==="

cd:
	make do-cd CD_DESCR="" CD_TYPE="cd" IMAGEFILE=${ISOFILE} DEV=${DEV}

cd-live:
	make do-cd CD_DESCR="live " CD_TYPE="cd-live" IMAGEFILE=${ISOLIVEFILE} DEV=${DEV}

cd-memlive:
	make do-cd CD_DESCR="live memory based " CD_TYPE="cd-memlive" IMAGEFILE=${ISOMEMLIVEFILE} DEV=${DEV}

do-cd:
	@[ -n "${DEV}" ] || (${ECHO} "Please specify a device using make ${CD_TYPE} DEV=..."; ${ECHO} "Possible devices:"; ${CDRECORD} -scanbus; ${FALSE})
	#@[ -c ${DEV} ] || (${ECHO} "Please specify a valid character device"; ${FALSE})
	@${ECHO} "===> Writing ${CD_DESCR}ISO image to ${DEV}"
	${MAKE} burn_iso DEV=${DEV} IMAGEFILE=${IMAGEFILE}

usb:
	make do-usb USB_DESCR="" USB_TYPE="cd" IMAGEFILE=${UFSFILE} DEV=${DEV}

usb-live:
	make do-usb USB_DESCR="live " USB_TYPE="cd-live" IMAGEFILE=${UFSLIVEFILE} DEV=${DEV}

usb-memlive:
	make do-usb USB_DESCR="live memory based " USB_TYPE="cd-memlive" IMAGEFILE=${UFSMEMLIVEFILE} DEV=${DEV}

do-usb:
	@[ -n "${DEV}" ] || (${ECHO} "Please specify a device using make ${USB_TYPE} DEV=..."; ${FALSE})
	@[ -c /dev/${DEV} ] || (${ECHO} "Please specify a valid character device"; ${FALSE})
	@${ECHO} "===> Writing ${UFS_DESCR}UFS image to /dev/${DEV}"
	${MAKE} partition_usb copy_ufs DEV=/dev/${DEV} IMAGEFILE=${IMAGEFILE}

${WRKDIR_COOKIE}:
	@${ECHO} "===> Making working directory"
	${MKDIR} -p ${WRKDIR}
	${CHOWN} root:wheel ${WRKDIR}

	${MKDIR} -p ${DISTFILES} ${PKGDIR}

	@${TOUCH} ${WRKDIR_COOKIE}

${BASEDIR_COOKIE}: ${WRKDIR_COOKIE}
	@${ECHO} "===> Making base directory"
	${MKDIR} -p ${BASEDIR}

	@${TOUCH} ${BASEDIR_COOKIE}

${BASE_COOKIE}: ${CONFIG_COPY_COOKIE} ${PORTS_COOKIE} ${SCRIPTS_COOKIE}
	@${TOUCH} ${BASE_COOKIE}

${BOOTSTRAP_COOKIE}: ${BOOTSTRAPSCRIPT_COOKIE} ${COMPRESS_COOKIE}
	@${TOUCH} ${BOOTSTRAP_COOKIE}

${WORLDSRC}:
	@${ECHO} "===> Building world from source..."
	${MAKE} -C ${SRCDIR} -j`sysctl -n hw.n${CP}u` buildworld TARGET=${TARGET}
	WORLDTMP=`mktemp -d /tmp/world.XXXXXX` && \
	${MAKE} -C ${SRCDIR} installworld distribution DESTDIR=$${WORLDTMP} TARGET=${TARGET} && \
	${TAR} -C $${WORLDTMP} -cJf ${WORLDSRC} . && \
	(${RM} -rf $${WORLDTMP} || (${CHFLAGS} -R 0 $${WORLDTMP}; ${RM} -rf $${WORLDTMP}))


# Extract the world (aka `make installworld distribution`)
# Compensate for x86 support in amd64 distributions
${WORLD_EXTRACT_COOKIE}: ${WORLDSRC} ${BASEDIR_COOKIE}
	@${ECHO} "===> Extracting userland files..."
	${TAR} -C ${BASEDIR} -xf ${WORLDSRC}
	-${LN} -s ld-elf.so.1 ${BASEDIR}/libexec/ld-elf32.so.1

	@${TOUCH} ${WORLD_EXTRACT_COOKIE}

${KERNELSRC}:
	@${ECHO} "===> Building kernel from source..."
	${MAKE} -C ${SRCDIR} -j`sysctl -n hw.n${CP}u` kernel-toolchain buildkernel KERNCONF=${KERNCONF} TARGET=${TARGET}
	KERNELTMP=`mktemp -d /tmp/kernel.XXXXXX` && \
	${MAKE} -C ${SRCDIR} installkernel DESTDIR=$${KERNELTMP} KERNCONF=${KERNCONF} TARGET=${TARGET} && \
	${TAR} -C $${KERNELTMP} -cJf ${KERNELSRC} . && \
	(${RM} -rf $${KERNELTMP} || (${CHFLAGS} -R 0 $${KERNELTMP}; ${RM} -rf $${KERNELTMP}))

# Extract the kernel (aka `make installkernel`)
${KERNEL_EXTRACT_COOKIE}: ${KERNELSRC} ${BASEDIR_COOKIE}
	@${ECHO} "===> Extracting kernel files..."
	${TAR} -C ${BASEDIR} -xf ${KERNELSRC}

	@${TOUCH} ${KERNEL_EXTRACT_COOKIE}

# Copy across user files (configuration files and others)
${CONFIG_COPY_COOKIE}: ${WORLD_EXTRACT_COOKIE} ${KERNEL_EXTRACT_COOKIE}
	@${ECHO} "===> Copying across user files..."
	${TOUCH} ${BASEDIR}/boot/loader.conf
	${TAR} -C ${FILESRC} -cf - . | ${TAR} -C ${BASEDIR} -xf -

	@${TOUCH} ${CONFIG_COPY_COOKIE}

# Prepare all directories required for bootstrapping
${BOOTSTRAPDIR_COOKIE}: ${CONFIG_COPY_COOKIE}
	@${ECHO} "===> Creating directories for bootstrap"
	${MKDIR} -p ${BOOTSTRAPDIR}
	(cd ${BOOTSTRAPDIR}; ${MKDIR} -p ${BOOTSTRAPDIRS} `cd ${BASEDIR}; ${FIND} boot -type d -depth 1`)

	@${TOUCH} ${BOOTSTRAPDIR_COOKIE}

# Copy across all userland files required for bootstrapping
${FILES_COPY_COOKIE}: ${BOOTSTRAPDIR_COOKIE} ${CONFIG_COPY_COOKIE}
	@${ECHO} "===> Copying userland files for bootstrap"
	${TAR} -C ${BASEDIR} -cf - rescue ${BOOTSTRAPFILES} | \
		${TAR} -C ${BOOTSTRAPDIR} -xf -

	@${TOUCH} ${FILES_COPY_COOKIE}

# Copy across all loader/kernel files required for bootstrapping
${LOADER_COOKIE}: ${FILES_COPY_COOKIE} ${BOOTSTRAPDIR_COOKIE}
	@${ECHO} "===> Copying loader/kernel files for bootstrap"
	(cd ${BASEDIR}; \
	  ${TAR} -cf - `${FIND} boot -type f -depth 1`) | ${TAR} -C ${BOOTSTRAPDIR} -xf -

	-(${TAR} -C ${BASEDIR} -cf - boot/defaults | ${TAR} -C ${BOOTSTRAPDIR} -xf -) 2> /dev/null
	-${CP} -fp ${BASEDIR}/usr/lib/kgzldr.o ${BOOTSTRAPDIR}/usr/lib 2> /dev/null

	@${TOUCH} ${LOADER_COOKIE}

# Patch the loader.conf file for bootstrapping
${PATCH_COOKIE}: ${LOADER_COOKIE}
	@${ECHO} "===> Patching the loader.conf for bootstrap"
	${ECHO} >> ${BOOTSTRAPDIR}/boot/loader.conf

	for module in ${BOOTSTRAPMODULES}; \
	do \
		if [ -z "`${GREP} ^$${module}_load=\"[Yy][Ee][Ss]\".\* ${BOOTSTRAPDIR}/boot/loader.conf`" ]; \
		then \
			${ECHO} "$${module}_load=\"YES\"" >> ${BOOTSTRAPDIR}/boot/loader.conf; \
		fi \
	done

	${ECHO} init_script=\"/chroot\" >> ${BOOTSTRAPDIR}/boot/loader.conf
	${ECHO} init_chroot=\"/base\" >> ${BOOTSTRAPDIR}/boot/loader.conf

	@${TOUCH} ${PATCH_COOKIE}

# Copy across all kernel objects required for bootstrap
${KERNEL_COPY_COOKIE}: ${PATCH_COOKIE}
	@${ECHO} "===> Copying kernel for bootstrap"
	${CP} -fp ${BASEDIR}/boot/kernel/kernel ${BOOTSTRAPDIR}/boot/kernel

	-${CP} -fp ${BASEDIR}/boot/kernel/a${CP}i.ko ${BOOTSTRAPDIR}/boot/kernel 2> /dev/null

	for module in `${GREP} '[0-9A-Za-z_]_load="[Yy][Ee][Ss]".*' ${BOOTSTRAPDIR}/boot/loader.conf | sed 's|_load="[Yy][Ee][Ss]".*||g' `; \
	do \
		[ ! -f ${BASEDIR}/boot/kernel/$${module}.ko ] || ${CP} -p ${BASEDIR}/boot/kernel/$${module}.ko ${BOOTSTRAPDIR}/boot/kernel; \
		[ ! -f ${BASEDIR}/boot/modules/$${module}.ko ] || ${CP} -p ${BASEDIR}/boot/modules/$${module}.ko ${BOOTSTRAPDIR}/boot/modules; \
	done

	@${TOUCH} ${KERNEL_COPY_COOKIE}

# Compress kernel objects
${COMPRESS_COOKIE}: ${KERNEL_COPY_COOKIE}
	@${ECHO} "===> Compressing the kernel"
	${GZIP} -f9 `${FIND} ${BOOTSTRAPDIR}/boot/kernel/ -type f ! -name '*.gz'` `${FIND} ${BOOTSTRAPDIR}/boot/modules/ -type f ! -name '*.gz'`

	@${TOUCH} ${COMPRESS_COOKIE}

# Write the bootstrap scripts
${BOOTSTRAPSCRIPT_COOKIE}: ${BOOTSTRAPDIR_COOKIE}
	@${ECHO} "===> Writing the bootstrap script"
	${CP} ${CHROOT_SCRIPT} ${BOOTSTRAPDIR}/${CHROOT}
	${SED} -i '' 	-e "s/%%MDMFS_SIZE%%/${MDMFS_SIZE}/" \
			-e "s/%%NAME_MEM_LIVE%%/${NAME_MEM_LIVE}/" \
			-e "s/%%NAME_UFS%%/${NAME_UFS}/" \
			${BOOTSTRAPDIR}/chroot
	${CHMOD} 0555 ${BOOTSTRAPDIR}/chroot

	@${TOUCH} ${BOOTSTRAPSCRIPT_COOKIE}

${BASECOMPRESSEDIMAGE}: ${UFSFILE}
	@${ECHO} "===> Compressing UFS Image of filesystem..."
	${MKUZIP} -s 8192 -o ${BASECOMPRESSEDIMAGE} ${UFSFILE}

.ORDER: ${BOOTSTRAP_COOKIE} ${ISOLIVEFILE} ${UFSLIVEFILE} ${BOOTSTRAPCOMPRESSEDIMAGE} ${LOADERBOOTSTRAP_COOKIE}

${BOOTSTRAPCOMPRESSEDIMAGE}: ${BOOTSTRAP_COOKIE} ${BASECOMPRESSEDIMAGE}
	@${ECHO} "===> Compressing bootstrap UFS Image..."
	${MV} ${BOOTSTRAPDIR}/boot ${WRKDIR}/

	${CP} ${BASECOMPRESSEDIMAGE} ${BOOTSTRAPDIR}/base.ufs.uzip

	${MAKEFS} ${BOOTSTRAPCOMPRESSEDIMAGE} ${BOOTSTRAPDIR} \
	  || (${MV} ${WRKDIR}/boot ${BOOTSTRAPDIR}/; ${RM} ${BOOTSTRAPDIR}/base.ufs.uzip; ${FALSE})
	${MV} ${WRKDIR}/boot ${BOOTSTRAPDIR}/
	${RM} ${BOOTSTRAPDIR}/base.ufs.uzip

	${TUNEFS} -L ${NAME_BTSTRP} ${BOOTSTRAPCOMPRESSEDIMAGE}
	${GZIP} -f9 ${BOOTSTRAPCOMPRESSEDIMAGE}
	${MV} ${BOOTSTRAPCOMPRESSEDIMAGE}.gz ${BOOTSTRAPCOMPRESSEDIMAGE}

${LOADERBOOTSTRAP_COOKIE}: ${BOOTSTRAP_COOKIE}
	@${ECHO} "===> Creating loader environment for compressed bootstrap image..."
	${MKDIR} -p ${LOADERBOOTSTRAPDIR} ${LOADERBOOTSTRAPDIR}/usr/lib

	-(${TAR} -C ${BOOTSTRAPDIR} -cf - boot | ${TAR} -C ${LOADERBOOTSTRAPDIR} -xf -)
	-${CP} -fp ${BOOTSTRAPDIR}/usr/lib/kgzldr.o ${LOADERBOOTSTRAPDIR}/usr/lib 2> /dev/null

	@${TOUCH} ${LOADERBOOTSTRAP_COOKIE}

.ORDER: ${ISOMEMLIVEFILE} ${UFSMEMLIVEFILE}

${ISOMEMLIVEFILE}: ${BOOTSTRAPCOMPRESSEDIMAGE} ${LOADERBOOTSTRAP_COOKIE}
	@${ECHO} "===> Creating Memory based Live ISO image"
	${CP} -p ${LOADERBOOTSTRAPDIR}/boot/loader.conf ${WRKDIR}/
	${ECHO} >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	${ECHO} "rootimg_load=\"YES\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	${ECHO} "rootimg_type=\"mfs_root\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	${ECHO} "rootimg_name=\"/boot/kernel/bootstrap.ufs\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	${ECHO} "vfs.root.mountfrom=\"ufs:/dev/ufs/${NAME_BTSTRP}\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf

	${CP} ${BASECOMPRESSEDIMAGE} ${LOADERBOOTSTRAPDIR}/boot/kernel/bootstrap.ufs.gz

	${MKISOFS} ${MKISOFLAGS}  -b boot/cdboot --no-emul-boot -volid ${NAME_MEM_LIVE} -o ${ISOMEMLIVEFILE} ${LOADERBOOTSTRAPDIR} \
	  || (${MV} ${WRKDIR}/loader.conf ${LOADERBOOTSTRAPDIR}/boot/; ${RM} ${LOADERBOOTSTRAPDIR}/boot/kernel/bootstrap.ufs.gz; ${FALSE})

	${MV} ${WRKDIR}/loader.conf ${LOADERBOOTSTRAPDIR}/boot/
	${RM} ${LOADERBOOTSTRAPDIR}/boot/kernel/bootstrap.ufs.gz

${UFSMEMLIVEFILE}: ${BOOTSTRAPCOMPRESSEDIMAGE} ${LOADERBOOTSTRAP_COOKIE}
	@${ECHO} "===> Creating Memory based Live UFS image"
	${CP} -p ${LOADERBOOTSTRAPDIR}/boot/loader.conf ${WRKDIR}/
	${ECHO} >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	${ECHO} "rootimg_load=\"YES\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	${ECHO} "rootimg_type=\"mfs_root\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	${ECHO} "rootimg_name=\"/boot/kernel/bootstrap.ufs\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf
	${ECHO} "vfs.root.mountfrom=\"ufs:/dev/ufs/${NAME_BTSTRP}\"" >> ${LOADERBOOTSTRAPDIR}/boot/loader.conf

	${CP} ${BASECOMPRESSEDIMAGE} ${LOADERBOOTSTRAPDIR}/boot/kernel/bootstrap.ufs.gz

	${MAKEFS} ${UFSMEMLIVEFILE} ${LOADERBOOTSTRAPDIR} \
	  || (${MV} ${WRKDIR}/loader.conf ${LOADERBOOTSTRAPDIR}/boot/; ${RM} ${LOADERBOOTSTRAPDIR}/boot/kernel/bootstrap.ufs.gz; ${FALSE})
	${TUNEFS} -L ${NAME_MEM_LIVE} ${UFSLIVEFILE}

	${MV} ${WRKDIR}/loader.conf ${LOADERBOOTSTRAPDIR}/boot/
	${RM} ${LOADERBOOTSTRAPDIR}/boot/kernel/bootstrap.ufs.gz

${PACKAGE_COOKIE}: ${WORLD_EXTRACT_COOKIE}
	@${ECHO} "===> Installing packages..."
	[ -z "`${MOUNT} | ${GREP} ${BASEDIR}`" ] || ${UMOUNT} `${MOUNT} | ${GREP} ${BASEDIR} | ${CUT} -f 3 -d ' ' | ${SORT} -r`
	${MOUNT} -t devfs devfs ${BASEDIR}/dev
	${MOUNT} -t nullfs ${PKGDIR} ${BASEDIR}/mnt
	for PKG in ${PKGS}; \
	do \
		pkgs=`cd ${BASEDIR}/mnt/All; ls $${PKG}*t[bg]z 2> /dev/null || true`; \
		if [ -n "$${pkgs}" ]; \
		then \
			${ECHO} "==> Installing packages: $${pkgs}"; \
			${CHROOT} ${BASEDIR} sh -c "cd /mnt/All && pkg_a${DD} -F $${pkgs}" || \
			  (${UMOUNT} ${BASEDIR}/dev ${BASEDIR}/mnt; ${FALSE}); \
		else \
			${ECHO} "==> No packages with name $${PKG}"; \
		fi; \
	done
	${UMOUNT} ${BASEDIR}/dev ${BASEDIR}/mnt

	@${TOUCH} ${PACKAGE_COOKIE}

_MOUNTDIRS=${BASEDIR}/tmp ${BASEDIR}/dev ${BASEDIR}/usr/freebsd ${BASEDIR}/usr/ports #${BASEDIR}/usr/ports/packages ${BASEDIR}/usr/freebsd/packages

${PORTS_COOKIE}: ${PACKAGE_COOKIE}
	@${ECHO} "===> Installing ports..."
.if !empty(${PORTS})
	[ -z "`${MOUNT} | ${GREP} ${BASEDIR}`" ] || ${UMOUNT} `${MOUNT} | ${GREP} ${BASEDIR} | ${CUT} -f 3 -d ' ' | ${SORT} -r`
	${MKDIR} -p ${BASEDIR}/usr/ports ${BASEDIR}/usr/ports/packages ${BASEDIR}/usr/freebsd
	${MOUNT} -t nullfs /usr/ports ${BASEDIR}/usr/ports
	${MOUNT} -t nullfs /usr/freebsd ${BASEDIR}/usr/freebsd
	${MOUNT} -t devfs devfs ${BASEDIR}/dev
	${MOUNT} -t tmpfs tmpfs ${BASEDIR}/tmp
	#${MOUNT} -t nullfs ${PKGDIR} ${BASEDIR}/usr/freebsd/packages
	#${MOUNT} -t nullfs ${PKGDIR} ${BASEDIR}/usr/ports/packages

	for PORT in ${PORTS}; \
	do \
		if [ -d ${BASEDIR}/usr/ports/$${PORT} ]; \
		then \
			pkg=`${CHROOT} ${BASEDIR} ${MAKE} -C /usr/ports/$${PORT} package-name`; \
			if [ ! -f "`ls ${BASEDIR}/usr/ports/packages/All/$${pkg}.t[bg]z 2> /dev/null`" ]; \
			then \
				${ECHO} "==> Building port: $${PORT} ($${pkg})"; \
				${CHROOT} ${BASEDIR} ${MAKE} -C /usr/ports/$${PORT} install package-recursive clean BATCH=yes DEPENDS_CLEAN=yes NOCLEANDEPENDS=yes || \
				  (${UMOUNT} ${_MOUNTDIRS}; ${FALSE}); \
			else \
				${ECHO} "==> Installing port: $${PORT} ($${pkg})"; \
				${CHROOT} ${BASEDIR} sh -c "cd /usr/ports/packages/All && pkg_a${DD} -F $${pkg}.t[bg]z" || \
				  (${UMOUNT} ${_MOUNTDIRS}; ${FALSE}); \
			fi; \
		else \
			${ECHO} "==> No port with name $${PORT}"; \
		fi; \
	done

	${UMOUNT} ${_MOUNTDIRS}
.endif

	@${TOUCH} ${PORTS_COOKIE}

${SCRIPTS_COOKIE}: ${PORTS_COOKIE}
	@${ECHO} "===> Running customising scripts..."
.for script in ${SCRIPTS}
.if ${SCRIPTSDIR} != ${_MASTERSCRIPTSDIR}
	if [ -x ${SCRIPTSDIR}/${script} ]; then \
		${ENV} BASEDIR=${BASEDIR} CONFIG=${CONFIG} ${SCRIPTSDIR}/${script}; \
	else \
		${ENV} BASEDIR=${BASEDIR} CONFIG=${CONFIG} ${_MASTERSCRIPTSDIR}/${script}; \
	fi
.else
	${ENV} BASEDIR=${BASEDIR} CONFIG=${CONFIG} ${SCRIPTSDIR}/${script}
.endif
.endfor

	@${TOUCH} ${SCRIPTS_COOKIE}

# Create an ISO image (from the base image)
${ISOFILE}: ${BASE_COOKIE}
	@${ECHO} "===> Creating ISO image"
	${CP} -p ${BASEDIR}/boot/loader.conf ${WRKDIR}/
	${CP} -p ${BASEDIR}/etc/rc.conf ${WRKDIR}/
	${ECHO} >> ${BASEDIR}/boot/loader.conf
	${ECHO} "vfs.root.mountfrom=\"cd9660:/dev/iso9660/${NAME}\"" >> ${BASEDIR}/boot/loader.conf
	if [ -z "`${GREP} root_rw_${MOUNT}= ${BASEDIR}/etc/rc.conf`" ]; then \
		${ECHO} >> ${BASEDIR}/etc/rc.conf; \
		${ECHO} 'root_rw_${MOUNT}="NO"' >> ${BASEDIR}/etc/rc.conf; \
	fi

	${MKISOFS} ${MKISOFLAGS}  -b boot/cdboot --no-emul-boot -volid ${NAME} -o ${ISOFILE} ${BASEDIR} \
          || (${MV} ${WRKDIR}/rc.conf ${BASEDIR}/etc/; ${MV} ${WRKDIR}/loader.conf ${BASEDIR}/boot/; ${FALSE})

	${MV} ${WRKDIR}/rc.conf ${BASEDIR}/etc/
	${MV} ${WRKDIR}/loader.conf ${BASEDIR}/boot/

# Create an ISO image with editable filesystem (live)
${ISOLIVEFILE}: ${BOOTSTRAP_COOKIE} ${BASECOMPRESSEDIMAGE}
	@${ECHO} "===> Creating Live ISO image"
	${CP} -p ${BOOTSTRAPDIR}/boot/loader.conf ${WRKDIR}/
	${ECHO} >> ${BOOTSTRAPDIR}/boot/loader.conf
	${ECHO} "vfs.root.mountfrom=\"cd9660:/dev/iso9660/${NAME_LIVE}\"" >> ${BOOTSTRAPDIR}/boot/loader.conf

	${CP} ${BASECOMPRESSEDIMAGE} ${BOOTSTRAPDIR}/base.ufs.uzip

	${MKISOFS} ${MKISOFLAGS}  -b boot/cdboot --no-emul-boot -volid ${NAME_LIVE} -o ${ISOLIVEFILE} ${BOOTSTRAPDIR} \
	  || (${MV} ${WRKDIR}/loader.conf ${BOOTSTRAPDIR}/boot/; ${RM} ${BOOTSTRAPDIR}/base.ufs.uzip; ${FALSE})

	${MV} ${WRKDIR}/loader.conf ${BOOTSTRAPDIR}/boot/
	${RM} ${BOOTSTRAPDIR}/base.ufs.uzip

# Create an UFS image (from the base image)
${UFSFILE}: ${BASE_COOKIE}
	@${ECHO} "===> Creating UFS Image"
	${CP} -p ${BASEDIR}/boot/loader.conf ${WRKDIR}/
	${ECHO} >> ${BASEDIR}/boot/loader.conf
	${ECHO} "vfs.root.mountfrom=\"ufs:/dev/ufs/${NAME}\"" >> ${BASEDIR}/boot/loader.conf

	${MAKEFS} ${UFSFILE} ${BASEDIR} \
	  || (${MV} ${WRKDIR}/loader.conf ${BASEDIR}/boot/; ${FALSE})
	${TUNEFS} -L ${NAME} ${UFSFILE}

	${MV} ${WRKDIR}/loader.conf ${BASEDIR}/boot/

${UFSLIVEFILE}: ${BOOTSTRAP_COOKIE} ${BASECOMPRESSEDIMAGE}
	@${ECHO} "===> Creating Live UFS image"
	${CP} -p ${BOOTSTRAPDIR}/boot/loader.conf ${WRKDIR}/
	${ECHO} >> ${BOOTSTRAPDIR}/boot/loader.conf
	${ECHO} "vfs.root.mountfrom=\"ufs:/dev/ufs/${NAME_LIVE}\"" >> ${BOOTSTRAPDIR}/boot/loader.conf

	${CP} ${BASECOMPRESSEDIMAGE} ${BOOTSTRAPDIR}/base.ufs.uzip

	${MAKEFS} ${UFSLIVEFILE} ${BOOTSTRAPDIR} \
	  || (${MV} ${WRKDIR}/loader.conf ${BOOTSTRAPDIR}/boot/; ${RM} ${BOOTSTRAPDIR}/base.ufs.uzip; ${FALSE})
	${TUNEFS} -L ${NAME_LIVE} ${UFSLIVEFILE}

	${MV} ${WRKDIR}/loader.conf ${BOOTSTRAPDIR}/boot/
	${RM} ${BOOTSTRAPDIR}/base.ufs.uzip

partition_usb: ${IMAGEFILE}
	@${ECHO} "===> Partitioning device ${DEV}"
	${FDISK} -BI ${DEV}
	${BSDLABEL} -Bwb ${BASEDIR}/boot/boot ${DEV}s1
	${ECHO} "8 partitions: \
^a: `du -Ak ${IMAGEFILE} | ${CUT} -f 1`k * 4.2BSD \
^b: * * 4.2BSD \
^c: * * unused" | tr '^' '\n' >> ${WRKDIR}/${BSDLABEL}
	${BSDLABEL} -R ${DEV}s1 ${WRKDIR}/${BSDLABEL}
	${RM} ${WRKDIR}/${BSDLABEL}
	${NEWFS} -EUL ${NAME_UFS} ${DEV}s1b

copy_ufs: ${IMAGEFILE}
	@${ECHO} "===> Copying UFS image to device ${DEV}..."
	${DD} if=${IMAGEFILE} of=${DEV}s1a bs=64k

burn_iso: ${IMAGEFILE}
	@${ECHO} "===> Burning ISO image to device ${DEV}..."
.if defined(BLANK)
	${CDRECORD} -v blank=${BLANK} dev=${DEV} -eject -data ${IMAGEFILE}
.else
	${CDRECORD} -v dev=${DEV} -overburn -eject -data ${IMAGEFILE}
.endif
	#burncd -e -f ${DEV} -s max blank data ${IMAGEFILE} fixate
