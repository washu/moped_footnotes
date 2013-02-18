# -*- encoding: utf-8 -*-
require File.expand_path('../lib/moped_footnotes/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Sal Scotto"]
  gem.email         = ["sal.scotto@gmail.com"]
  gem.description   = %q{Creat a footnote for moped calls.}
  gem.summary       = %q{Ads a new footnote for rails-footnote to log moped queries}
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.name          = "moped_footnotes"
  gem.require_paths = ["lib"]
  gem.version       = MopedFootnotes::VERSION
  gem.licenses       = ["MIT"]
  gem.rubygems_version = %q{1.5.3}
  gem.add_runtime_dependency(%q<moped>, [">= 0"])
  gem.add_runtime_dependency(%q<rails>, [">= 0"])
  gem.add_runtime_dependency(%q<activesupport>, [">= 0"])
  gem.add_runtime_dependency(%q<rails-footnotes>, [">= 0"])
end
