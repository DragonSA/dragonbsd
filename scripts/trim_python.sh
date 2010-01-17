#!/bin/sh

. `dirname $0`/common.shlib

find ${BASEDIR}/usr/local/lib ! -type d -name '*.pyc' -or -name '*.pyo' -delete
