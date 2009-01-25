#!/bin/sh

find /usr/local/lib ! -type d -name '*.pyc' -or -name '*.pyo' -delete

