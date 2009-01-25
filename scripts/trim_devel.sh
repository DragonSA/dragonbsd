#!/bin/sh

find /usr/lib ! -type d -name '*.a' -delete
find /usr/local/lib ! -type d -name '*.a' -or -name '*.la'  -delete

rm -rf /usr/include /usr/local/include
mkdir /usr/include /usr/local/include

