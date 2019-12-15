#shell #!/usr/bin/env bash
#shell # This conditional is evaluated as true in Ruby, false in shell
#shell if [ ]; then
#shell eval <<'END_OF_RUBY'
#shell # -- begin Ruby --
#!/usr/bin/env ruby

# Ruby-port of the Bazel's wrapper script for Python

# Copyright 2017 The Bazel Authors. All rights reserved.
# Copyright 2019 BazelRuby Authors. All rights reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

def main(args)
  custom_loadpaths = {loadpaths}
  rubyopt = {rubyopt}
  main = {main}

  Runfiles.new(custom_loadpaths, rubyopt).exec(main, *args)
  # TODO(yugui) Support windows
end

if __FILE__ == $0
  main(ARGV)
end
#shell END_OF_RUBY
#shell __END__
#shell # -- end Ruby --
#shell fi
#shell # -- begin Shell Script --
#shell 
#shell # --- begin runfiles.bash initialization v2 ---
#shell # Copy-pasted from the Bazel Bash runfiles library v2.
#shell set -uo pipefail; f=bazel_tools/tools/bash/runfiles/runfiles.bash
#shell source "${RUNFILES_DIR:-/dev/null}/$f" 2>/dev/null || \
#shell source "$(grep -sm1 "^$f " "${RUNFILES_MANIFEST_FILE:-/dev/null}" | cut -f2- -d' ')" 2>/dev/null || \
#shell source "$0.runfiles/$f" 2>/dev/null || \
#shell source "$(grep -sm1 "^$f " "$0.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
#shell source "$(grep -sm1 "^$f " "$0.exe.runfiles_manifest" | cut -f2- -d' ')" 2>/dev/null || \
#shell { echo>&2 "ERROR: cannot find $f"; exit 1; }; f=; set -e
#shell # --- end runfiles.bash initialization v2 ---
#shell 
#shell exec "$(rlocation {interpreter})" -r"$(rlocation @bazelruby_ruby_rules//ruby/private/tools:runfiles.rb)" ${BASH_SOURCE:-$0} "$@"
