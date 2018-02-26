toolchain_root = File.dirname(__FILE__)
path = File.join(toolchain_root, 'loadpath.lst')

$LOAD_PATH = File.foreach(path).map do |path|
  File.absolute_path(path, toolchain_root)
end
