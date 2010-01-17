#!/bin/sh

. `dirname $0`/common.shlib

find ${BASEDIR}/boot ! -type d -name '*.symbols' -delete
