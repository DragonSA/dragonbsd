#!/bin/sh

. common.shlib

find ${BASEDIR}/boot ! -type d -name '*.symbols' -delete
