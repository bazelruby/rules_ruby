require 'rbconfig'
require 'shellwords'

# Based on the Bazel's binary wrapper script for Python

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

require 'rbconfig'
require 'shellwords'

class Runfiles
  def initialize(load_paths, rubyopt)
    @runfiles = find_runfiles
    @rubyopt = rubyopt

    loadpaths = create_loadpath_entries(load_paths, @runfiles)
    loadpaths += get_repository_imports(@runfiles)
    loadpaths += ENV['RUBYLIB'].split(':') if ENV.key?('RUBYLIB')
    @loadpaths = loadpaths
  end

  def exec(program, program_opts:, argv:)
    runfiles_envkey, runfiles_envvalue = runfiles_envvar(runfiles)
    ENV[runfiles_envkey] = runfiles_envvalue if runfiles_envkey
    ENV['RUBYOPT'] = Shellwords.join(expand_vars(@rubyopt))
    ENV['RUBYLIB'] = @loadpaths.join(':')

    program_opts = expand_vars(program_opts || [])
    exec(program, *program_opts, *argv)
  end

  def exec_script(script, *argv)
    ruby = find_ruby_program
    script = File.join(@runfiles, script)
    exec(ruby, argv: [script, *argv])
  end

  private
  def find_runfiles
    stub_filename = File.absolute_path($0)
    runfiles = "#{stub_filename}.runfiles"
    loop do
      case
      when File.directory?(runfiles)
        return runfiles
      when %r!(.*\.runfiles)/.*!o =~ stub_filename
        return $1
      when File.symlink?(stub_filename)
        target = File.readlink(stub_filename)
        stub_filename = File.absolute_path(target, File.dirname(stub_filename))
      else
        break
      end
    end
    raise "Cannot find .runfiles directory for #{$0}"
  end

  def create_loadpath_entries(custom, runfiles)
    [runfiles] + custom.map {|path| File.join(runfiles, path) }
  end

  def get_repository_imports(runfiles)
    Dir.children(runfiles).map {|d|
      File.join(runfiles, d)
    }.select {|d|
      File.directory? d
    }
  end

  # Finds the runfiles manifest or the runfiles directory.
  def runfiles_envvar(runfiles)
    # If this binary is the data-dependency of another one, the other sets
    # RUNFILES_MANIFEST_FILE or RUNFILES_DIR for our sake.
    manifest = ENV['RUNFILES_MANIFEST_FILE']
    if manifest
      return ['RUNFILES_MANIFEST_FILE', manifest]
    end

    dir = ENV['RUNFILES_DIR']
    if dir
      return ['RUNFILES_DIR', dir]
    end

    # Look for the runfiles "output" manifest, argv[0] + ".runfiles_manifest"
    manifest = runfiles + '_manifest'
    if File.exists?(manifest)
      return ['RUNFILES_MANIFEST_FILE', manifest]
    end

    # Look for the runfiles "input" manifest, argv[0] + ".runfiles/MANIFEST"
    manifest = File.join(runfiles, 'MANIFEST')
    if File.exists?(manifest)
      return ['RUNFILES_DIR', manifest]
    end

    # If running in a sandbox and no environment variables are set, then
    # Look for the runfiles  next to the binary.
    if runfiles.end_with?('.runfiles') and File.directory?(runfiles)
      return ['RUNFILES_DIR', runfiles]
    end
  end

  def find_ruby_program
    File.join(
      RbConfig::CONFIG['bindir'],
      RbConfig::CONFIG['ruby_install_name'],
    )
  end

  def expand_vars(args)
    args.map do |arg|
      arg.gsub(/\${(.+?)}/o) do
        case $1
        when 'RUNFILES_DIR'
          runfiles
        else
          ENV[$1]
        end
      end
    end
  end
end
