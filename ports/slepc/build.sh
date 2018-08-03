#!/usr/bin/bash
set -e
export PATH=$PATH:/usr/bin
# Export HTTP(S)_PROXY as http(s)_proxy:
if [ "$HTTP_PROXY" ]; then
    export http_proxy=$HTTP_PROXY
fi
if [ "$HTTPS_PROXY" ]; then
    export https_proxy=$HTTPS_PROXY
fi
pacman -Sy --noconfirm --needed diffutils make python2

PATH_TO_BUILD_DIR="`cygpath "$1"`"
shift
VCPKG_INSTALL_BIN_DIR="`cygpath "$1"`"
shift

export PATH=$VCPKG_INSTALL_BIN_DIR:$PATH

cd "$PATH_TO_BUILD_DIR"
echo "=== CONFIGURING ==="
python2 "$@"
echo "=== Fixing ==="
/usr/bin/find ./src -name *.c -type f -exec sed -i 's/PETSC_EXTERN/SLEPC_EXTERN/g' {} +
echo "=== BUILDING ==="
make
echo "=== INSTALLING ==="
make install
