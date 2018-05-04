#!/bin/sh -eu
VERSION=$1
if [ -z "$VERSION" ]; then
  echo "Usage: install-bazel.sh BAZEL_VERSION" >&2
  exit 1
fi

INSTALLER=bazel-$VERSION-installer-linux-x86_64.sh
RELEASE_BASE_URI=https://github.com/bazelbuild/bazel/releases/download/$VERSION

REQUIRE_INSTALL=true
if test -x $HOME/local/$INSTALLER; then
  cd $HOME/local
  if curl $RELEASE_BASE_URI/$INSTALLER.sha256 | sha256sum -c; then
    REQUIRE_INSTALL=false
  fi
fi

if $REQUIRE_INSTALL; then
  rm -rf $HOME/local
  mkdir $HOME/local
  cd $HOME/local
  wget $RELEASE_BASE_URI/$INSTALLER
  chmod +x $INSTALLER
  ./$INSTALLER --prefix=$HOME/local --base=$HOME/.bazel
fi
