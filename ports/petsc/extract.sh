#!/usr/bin/bash
set -e
export PATH=$PATH:/usr/bin
pacman -Sy --noconfirm --needed tar

ARCHIVE="`cygpath "$1"`"

tar -xvf $ARCHIVE
