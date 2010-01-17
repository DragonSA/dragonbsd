#!/bin/sh

. common.shlib

find ${BASEDIR}/usr/lib ! -type d -name '*.a' -delete
find ${BASEDIR}/usr/local/lib ! -type d -name '*.a' -or -name '*.la'  -delete

rm -rf ${BASEDIR}/usr/include ${BASEDIR}/usr/local/include
mkdir ${BASEDIR}/usr/include ${BASEDIR}/usr/local/include

# TODO: remove gcc/llvm
