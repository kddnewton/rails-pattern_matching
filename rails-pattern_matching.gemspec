# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "rails/pattern_matching/version"

Gem::Specification.new do |spec|
  spec.name = "rails-pattern_matching"
  spec.version = Rails::PatternMatching::VERSION
  spec.authors = ["Kevin Newton"]
  spec.email = ["kddnewton@gmail.com"]

  spec.summary = "Pattern matching for Rails applications"
  spec.homepage = "https://github.com/kddnewton/rails-pattern_matching"
  spec.license = "MIT"

  spec.files =
    Dir.chdir(File.expand_path("..", __FILE__)) do
      `git ls-files -z`.split("\x0")
        .reject { |f| f.match(%r{^(test|spec|features)/}) }
    end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.metadata = { "rubygems_mfa_required" => "true" }

  spec.add_dependency "activemodel"
  spec.add_dependency "activerecord"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "sqlite3"
  spec.add_development_dependency "syntax_tree"
  spec.add_development_dependency "test-unit"
end
