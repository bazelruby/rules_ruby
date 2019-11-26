# frozen_string_literal: true

toolchain_root = File.dirname(__FILE__)
list_file = File.join(toolchain_root, 'loadpath.lst')

system_paths = {}
File.foreach(list_file) do |path|
  system_paths['/' + path.chomp] = true
end

$LOAD_PATH.map! do |path|
  if system_paths[path]
    File.absolute_path(path[1..-1], toolchain_root)
  else
    path
  end
end
