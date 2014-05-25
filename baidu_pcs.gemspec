# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'baidu_pcs/version'

Gem::Specification.new do |spec|
  spec.name          = "baidu_pcs"
  spec.version       = BaiduPcs::VERSION
  spec.authors       = ["cao7113"]
  spec.email         = ["cao7113@hotmail.com"]
  spec.description   = %q{Baidu Pcs: personal cloud service}
  spec.summary       = spec.description
  spec.homepage      = "http://shareup.me"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_runtime_dependency "typhoeus", "~> 0.6.5"
  spec.add_runtime_dependency "multi_json"
  spec.add_runtime_dependency "oj"
  spec.add_runtime_dependency "thor" #slop
end
