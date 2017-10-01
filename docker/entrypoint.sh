#!/bin/bash -l

set -e

# Set env vars for bundle and rbenv
export BUNDLE_PATH=/var/local/bundle_cache
export PATH="$RBENV_ROOT/bin:$PATH"
export BUILD_UID=$usr

eval "$(rbenv init -)"

# add user with same uid as host user
echo " >> Adding user builder with uid $BUILD_UID ..."
useradd --shell /bin/bash -u $BUILD_UID builder

# chown dirs needed
echo " >> chowning $BUNDLE_PATH and /simp-core ..."
chown -R builder:builder /simp-core
chown -R builder:builder $BUNDLE_PATH

# run docker cmd as the right user
echo " >> running command as you ..."
echo runuser -u builder -- "$@"
eval runuser -u builder -- "$@"

