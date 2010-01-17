#!/bin/sh

. `dirname $0`/common.shlib

find ${BASEDIR}/usr/share -type d -name doc | xargs rm -rf
find ${BASEDIR}/usr/local/share -type d -name doc | xargs rm -rf

