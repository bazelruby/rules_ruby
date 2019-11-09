#!/usr/bin/env bash
#
# Bazel Helpers
# Depends on BashMatic library.
#

Bazel__Flags="--max_idle_secs=5"

Bazel::Commands() {
  bazel "${Bazel__Flags}" 2>/dev/null | egrep '^\s{2}[a-z]' | grep -v '  bazel' | awk '{print $1}'
}


Bazel::LoadCommands() {
  if [[ -z "${Bazel__CommandArray[*]}" ]]; then
    export -a Bazel__CommandArray=( $(Bazel::Commands) )
  fi
}

__Bazel::Targets() {
  local filter="${1}"
  bazel ${Bazel__Flags} query //...:all 2>/dev/null | egrep "${filter}"
}

Bazel::Targets() {
  local filter="$1"
  local cmd=
  if [[ -z ${filter} ]] ; then
    cmd="bazel ${Bazel__Flags} query //...:all 2>/dev/null"
  else
    cmd="bazel ${Bazel__Flags} query //...:all 2>/dev/null | egrep \"${filter}\""
  fi
  run::set-next show-output-on
  run "${cmd}"
}


Bazel::Do() {
  local action="${1:-"build"}"; shift
  [[ ${action} == "run" ]] && run::set-next show-output-on

  local targeting="$1"
  if [[ -z ${targeting} ]]; then
    Bazel::Action "${action}" "//...:all"
  else
    local -a targets=($(__Bazel::Targets "${targeting}"))
    if [[ ${#targets[@]} -eq 1 ]]; then
      Bazel::Action "${action}" "${targets[0]}"
    elif [[ ${#targets[@]} -gt 1 ]] ; then
      h1 "More than one target matched: " ${targets[*]}
      lib::run::ask "Run them all?"
      for target in ${targets[@]}; do
        Bazel::Action "${action}" "${target}"
      done
    else
      info "No targets matched argument ${targeting}"
    fi
  fi
}

Bazel::Action() {
  local action="$1"
  local target="$2"

  [[ -z "${action}${target}" ]] && return

  h2 "action: ${action} ——> target: ${bldylw}${target}"
  run "bazel ${action} ${target} ${Bazel__Flags}"
}

Bazel::CommandMatching() {
  local starts_with="$1"
  local len=${#starts_with}

  Bazel::LoadCommands

  local -a matches=()
  for command in "${Bazel__CommandArray[@]}"; do
    if [[ "${command:0:${len}}" == "${starts_with}" ]]; then
      matches=( "${matches[@]}" "${command}" )
    fi
  done

  if [[ ${#matches[@]} -eq 1 ]] ; then
    printf "%s" ${matches[0]}
    return 0
  elif [[ ${#matches[@]} -gt 1 ]] ; then
    error "More than one command matched ${starts_with}:" "${matches[@]}"
    return 1
  else
    error "No command matched ${starts_with}."
    return 2
  fi
}
