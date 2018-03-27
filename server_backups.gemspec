
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "server_backups/version"

Gem::Specification.new do |spec|
  spec.name          = "server_backups"
  spec.version       = ServerBackups::VERSION
  spec.authors       = ["Tyler Gannon"]
  spec.email         = ["tgannon@gmail.com"]

  spec.summary       = %q{For taking backups of servers.}
  spec.description   = %q{For taking backups of servers.}
  spec.homepage      = "https://github.com/tylergannon/server_backups"
  spec.license       = "MIT"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  spec.add_dependency "main", "~> 6.2"
  spec.add_dependency "activesupport", "~> 5.1"
  spec.add_dependency "aws-sdk-s3", "~> 1.8"

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = "bin"
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.16"
  spec.add_development_dependency "rake", "~> 10.5"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "vcr", "~> 4.0"
  spec.add_development_dependency "webmock", "~> 3.3"
end
