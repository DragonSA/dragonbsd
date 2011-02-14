.MAIN:	usage

usage:
	@${ECHO} "usage: make [targets]"

help: usage
	@${ECHO}
	@${ECHO} "Creates an image file containing a full FreeBSD distribution.  The image"
	@${ECHO} "format can be specified ('ISO' for CD/DVD or 'UFS' for mass storage).  The"
	@${ECHO} "type of bootable system can also be specified ('normal' or 'live')."
	@${ECHO}
	@${ECHO} "Multiple targets
	@${ECHO}
	@${ECHO} "The following targets are available:"
	@${ECHO} "Types:"
	@${ECHO} "	iso		Creates a ISO image"
	@${ECHO} "	iso-live	Creates a live ISO image"
	@${ECHO} "	iso-memlive	Creates a live memory based ISO image"
	@${ECHO} "	ufs		Creates a UFS image"
	@${ECHO} "	ufs-live	Creates a live UFS image"
	@${ECHO} "	ufs-memlive	Creates a live memory based UFS image"
	@${ECHO}
	@${ECHO} "Composites:"
	@${ECHO} "	all		Creates all the types above"
	@${ECHO} "	live		Creates all the live types above"
	@${ECHO} "	memlive		Creates all the live memory based types above"
	@${ECHO}
	@${ECHO} "Utilities:"
	@${ECHO} "	clean		Remove all working files
	@${ECHO} "	cd		Writes a ISO image to a CD/DVD device*"
	@${ECHO} "	cd-live		Writes a live ISO image to a CD/DVD device*"
	@${ECHO} "	cd-memlive	Writes a live memory based ISO image to a CD/DVD device*"
	@${ECHO} "	usb		Writes a UFS image to a (USB) mass storage device**"
	@${ECHO} "	usb-live	Writes a live UFS image to a (USB) mass storage device**"
	@${ECHO} "	usb-memlive	Writes a live memory based UFS image to a (USB) mass "
	@${ECHO} "			storage device**"
	@${ECHO} "*the device to write too must be specified using DEV (eg make cd DEV=0,0,0)"
	@${ECHO} "**the device to write too must be specified using DEV (eg make usb DEV=da0)"
	@${ECHO}
	@${ECHO} "Help:"
	@${ECHO} "	help		Displays this help message"
	@${ECHO} "	help-[type]	Displays discription for [type] image (from above) [TODO]"
	@${ECHO} "	help-config	Displays information for customising a system image"
	@${ECHO} "	help-config-all	Displays all information for customising a system image"
	@${ECHO} "	help-scripts	Displays information about post processing scripts"
	@${ECHO}
	#@${ECHO} "???For further help see the manual pages (eg man dragonbsd) [TODO]"

help-clean:
	@${ECHO} "target: clean
	@${ECHO}
	@${ECHO} "Clean the working directory safely (WRKDIR).  The schg flag"
	@${ECHO} "is cleared, all mounted filesystems are unmounted and all"
	@${ECHO} "files are removed"

help-config:
	@${ECHO} "All customisable variables"
	@${ECHO}
	@${ECHO} "WRKDIR:	A temporary working directory used when generating files"
	@${ECHO} "		[default: $${PWD}/$${NAME}]"
	@${ECHO} "TARGET:	The target architecture for the system (has to be compatible"
	@${ECHO} "		with this system"
	@${ECHO} "		[default: ${UNAME_p}]"
	@${ECHO} "NAME:		The name of the system.  Used for naming the generated files"
	@${ECHO} "		[default: DragonBSD]"
	@${ECHO} "FILES:	Use files to copy into base image"
	@${ECHO} "		[default: $${PWD}/files]"
	@${ECHO} "PKGS:		Packages to install in base image"
	@${ECHO} "		[default: ]"
	@${ECHO} "PORTS:	Ports to install in base image"
	@${ECHO} "		[default: ]"
	@${ECHO} "SCRIPTS:	Post processing cleanup scripts (see help-scripts)"
	@${ECHO} "		[default: ]"

help-config-all:
	@${ECHO} "WIP"
	@${ECHO} "NAME:		The name of the system.  Used for naming the generated files"
	@${ECHO} "		[default: DragonBSD]"
	@${ECHO} "	NAME_BTSTRP:	Name of the bootstrap UFS filesystem"
	@${ECHO} "			[default: $${NAME}BTSTRP]"
	@${ECHO} "	NAME_LIVE:	Name of the live UFS/ISO image"
	@${ECHO} "			[default: $${NAME}Live]
	@${ECHO} "	NAME_MEM_LIVE:	Name of the memory based live UFS/ISO image"
	@${ECHO} "			[default: $${NAME}MEMLive]"
	@${ECHO} "	NAME_UFS:	Name of the UFS overlay filesystem"
	@${ECHO} "			[default: $${NAME}UFS]"
	@${ECHO} "
	@${ECHO} "MDMFS_SIZE:	Size of temporary filesystem (for live systems)"
	@${ECHO} "		[default: 32m]"
	@${ECHO} "CHROOT_SCRIPT:	The script that initialises the live environment"
	@${ECHO} "		[default: ${.CURDIR}/chroot]"
	@${ECHO}
	@${ECHO} "SRCDIR:	Location of FreeBSD sources (required to build kernel and world)"
	@${ECHO} "		[default: /usr/src]"
	@${ECHO} "KERNCONF:	Kernel configuration file"
	@${ECHO} "		[default: GENERIC]"
	@${ECHO} "TARGET:	The target architecture for the system (has to be compatible"
	@${ECHO} "		with this system"
	@${ECHO} "		[default: ${UNAME_p}]"
	@${ECHO}
	@${ECHO} "WRKDIR:	A temporary working directory used when generating files"
	@${ECHO} "		[default: $${PWD}/$${NAME}]"
	@${ECHO} "	BASEDIR:	Directory for raw system files"
	@${ECHO} "			[default: $${WRKDIR}/base]"
	@${ECHO} "	BOOTSTRAPDIR:	Directory for bootstrap files"
	@${ECHO} "			[default: $${WRKDIR}/bootstrap]"
	@${ECHO} "DISTFILES:	Location of system and port packages"
	@${ECHO} "		[default: $${PWD}/distfiles]
	@${ECHO} "	PKGDIR:		Location of port packages"
	@${ECHO} "			[default: $${DISTFILES}/packages]"
	@${ECHO} "	KERNELSRC:	Location of kernel package"
	@${ECHO} "			[default: $${DISTFILES}/kernel.tar.xz]"
	@${ECHO} "	WORLDSRC:	Location of world and distribution package"
	@${ECHO} "			[default: $${DISTFILES}/world.tar.xz]"
	@${ECHO} "FILES:	Use files to copy into base image"
	@${ECHO} "		[default: $${PWD}/files]"
	@${ECHO} "SCRIPTSDIR:	Location of post processing scripts"
	@${ECHO} "		[default: ${.CURDIR}/scripts]"
	@${ECHO}
	@${ECHO} "PKGS:		Packages to install in base image"
	@${ECHO} "		[default: ]"
	@${ECHO} "PORTS:	Ports to install in base image"
	@${ECHO} "		[default: ]"
	@${ECHO} "SCRIPTS:	Post processing cleanup scripts (see help-scripts)"
	@${ECHO} "		[default: ]"

help-scripts:
	@${ECHO} "TODO"
