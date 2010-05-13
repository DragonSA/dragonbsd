#!/bin/sh

. `dirname $0`/common.shlib

find ${BASEDIR}/ -type d -name .svn | xargs rm -rf

