#!/bin/sh

echo "DragonBSD::::::DragonBSD LiveCD User::csh:" | adduser -f - -w none
pw user mod DragonBSD -G operator,wheel
echo -n "DragonBSD" | pw user mod DragonBSD -h 0

