# frozen_string_literal: true

require_relative "lib/appraisal/matrix/version"

Gem::Specification.new do |spec|
  spec.name = "appraisal-matrix"
  spec.version = Appraisal::Matrix::VERSION
  spec.authors = ["Drew Caddell"]
  spec.email = ["dcaddell@invoca.com"]

  spec.summary = "Appraisal file DSL for generating a matrix of gemfiles."
  spec.description = "Appraisal file DSL for generating a matrix of gemfiles."
  spec.homepage = "https://github.com/invoca/appraisal-matrix"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"

  spec.metadata["homepage_uri"] = spec.homepage

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git .github appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Appraisal added the AppraisalFile class (that this gem prepends) in version 2.2.0
  spec.add_dependency "appraisal", "~> 2.2"
end
