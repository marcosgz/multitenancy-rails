# frozen_string_literal: true

require_relative "lib/multitenancy/version"

Gem::Specification.new do |spec|
  spec.name = "multitenancy-rails"
  spec.version = Multitenancy::VERSION
  spec.authors = ["Marcos G. Zimmermann"]
  spec.email = ["mgzmaster@gmail.com"]

  spec.summary = "Multitenancy for Rails applications"
  spec.description = "Multitenancy for Rails applications"
  spec.homepage = "https://github.com/marcosgz/multitenancy-rails"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1"

  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/marcosgz"
    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/marcosgz/multitenancy-rails"
    spec.metadata["changelog_uri"] = "https://github.com/marcosgz/multitenancy-rails/blob/main/CHANGELOG.md"
  end

  gemspec = File.basename(__FILE__)
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).reject do |f|
      (f == gemspec) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "zeitwerk"
  spec.add_dependency "activesupport"
  spec.add_dependency "railties"
  spec.add_development_dependency "standard"
end
