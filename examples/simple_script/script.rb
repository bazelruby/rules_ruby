require 'openssl'
require 'lib/foo'

def oss_rand()
	return "#{OpenSSL::BN.rand(512)}"
end

puts Foo.aha() + " " + oss_rand()