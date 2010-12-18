.MAIN:	usage

usage:
	@${ECHO} "usage: make [targets]"

help: usage
	@${ECHO}
	@${ECHO} "Creates an image file containing a full FreeBSD distribution.  The image format"
	@${ECHO} "can be specified ('ISO' for CD/DVD or 'UFS' for mass storage).  The type of"
	@${ECHO} "bootable system can also be specified ('normal' or 'live')."
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
	@${ECHO} "	usb-memlive	Writes a live memory based UFS image to a (USB) mass storage device**"
	@${ECHO} "*the device to write too must be specified using DEV (eg make cd DEV=0,0,0)"
	@${ECHO} "**the device to write too must be specified using DEV (eg make usb DEV=/dev/da0)"
	@${ECHO}
	@${ECHO} "Help:"
	@${ECHO} "	help		Displays this help message"
	@${ECHO} "	help-[type]	Displays discription for [type] image (from above) [TODO]"
	@${ECHO} "	help-config	Displays information for customising a system image [TODO]"
	@${ECHO} "	help-config-all	Displays all information for customising a system image"
	@${ECHO}
	@${ECHO} "???For further help see the manual pages (eg man dragonbsd) [TODO]"

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
	@${ECHO} "		[default: $${PWD}/work/]
	@${ECHO} "TARGET:	The target architecture for the system (has to be compatible"
	@${ECHO} "		with this system"
	@${ECHO} "		[default: ${UNAME_p}]"
	@${ECHO} "NAME:		The name of the system.  Used for naming the generated files"
	@${ECHO} "		[default: DragonBSD]"

help-config-all:
	@${ECHO} "NAME: System name variables"
	@${ECHO} "	NAME_BTSTRP:	Name of the bootstrap UFS filesystem"
	@${ECHO} "			[default: $${NAME}BTSTRP]"
	@${ECHO} "	NAME_LIVE:	Name of the live UFS/ISO image"
	@${ECHO} "			[default: $${NAME}Live]
	@${ECHO} "	NAME_MEM_LIVE:	Name of the memory based live UFS/ISO image"
	@${ECHO} "			[default: $${NAME}MEMLive]"
	@${ECHO} "	NAME_UFS:	Name of the UFS overlay filesystem"
	@${ECHO} "			[default: $${NAME}UFS]"
