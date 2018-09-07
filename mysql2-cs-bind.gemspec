# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.name          = "mysql2-cs-bind"
  gem.version       = "0.0.7"
  gem.authors       = ["TAGOMORI Satoshi"]
  gem.email         = ["tagomoris@gmail.com"]
  gem.homepage      = "https://github.com/tagomoris/mysql2-cs-bind"
  gem.summary       = %q{extension for mysql2 to add client-side variable binding}
  gem.description   = %q{extension for mysql2 to add client-side variable binding, by adding method Mysql2::Client#xquery}

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "mysql2"  

  # tests
  gem.add_development_dependency 'eventmachine'
  gem.add_development_dependency 'rake-compiler', "~> 0.7.7"
  gem.add_development_dependency 'rake', '0.8.7' # NB: 0.8.7 required by rake-compiler 0.7.9
  gem.add_development_dependency 'rspec', '2.10.0'
end
