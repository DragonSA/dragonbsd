#!/bin/sh

find /usr/share -type d -name doc | xargs rm -rf
find /usr/local/share -type d -name doc | xargs rm -rf

