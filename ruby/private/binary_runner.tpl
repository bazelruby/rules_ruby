#!/bin/sh

if [ -n "${RUNFILES_DIR+x}" ]; then
  PATH_PREFIX=$RUNFILES_DIR/{workspace_name}/
elif [ -s `dirname $0`/../../MANIFEST ]; then
  PATH_PREFIX=`cd $(dirname $0); pwd`/
elif [ -d $0.runfiles ]; then
  PATH_PREFIX=`cd $0.runfiles; pwd`/{workspace_name}/
else
  echo "WARNING: it does not look to be at the .runfiles directory" >&2
  exit 1
fi

$PATH_PREFIX{interpreter} -I${PATH_PREFIX} ${PATH_PREFIX}{main} "$@"