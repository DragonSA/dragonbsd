#!/bin/sh

. common.shlib

USER=${USER:-DragonBSD}

pw -V ${BASEDIR}/etc user add ${USER} -c "${USER} LiveSYS User" -G operator,wheel -s tcsh -w yes
pw -V ${BASEDIR}/etc user mod ${USER} -m
