#!/bin/sh -e

if [ -n "${RUNFILES_DIR+x}" ]; then
  PATH_PREFIX=$RUNFILES_DIR/{workspace_name}/
elif [ -d $0.runfiles ]; then
  PATH_PREFIX=`cd $0.runfiles; pwd`/{workspace_name}/
else
  PATH_PREFIX=`cd $(dirname $0); pwd`/
fi

exec ${PATH_PREFIX}{rel_interpreter_path} "$@"