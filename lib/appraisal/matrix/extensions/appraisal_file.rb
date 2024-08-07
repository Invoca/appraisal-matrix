# frozen_string_literal: true

require 'appraisal'
require 'appraisal/matrix/rubygems_helper'

module Appraisal::Matrix
  module AppraiseFileWithMatrix

    class VersionArray
      SUPPORTED_VERSION_STEPS = [:major, :minor, :patch].freeze

      attr_reader :gem_name, :version_requirements, :step

      def initialize(gem_name:, versions:, step: :minor)
        SUPPORTED_VERSION_STEPS.include?(step) or raise("Unsupported version step: #{step}")

        @gem_name = gem_name
        @version_requirements = Gem::Requirement.new(versions)
        @step = step.to_sym
      end

      def versions
        RubygemsHelper.versions_to_test(gem_name, version_requirements, step)
      end
    end

    # Define a matrix of appraisals to test against
    # Expected usage:
    #   appraisal_matrix(rails: "6.0")
    #   appraisal_matrix(rails: "> 6.0.3")
    #   appraisal_matrix(rails: [">= 6.0", "< 7.1"])
    #   appraisal_matrix(rails: { versions: [">= 6.0", "< 7.1"], step: "major" })
    #   appraisal_matrix(rails: "6.0") do
    #     gem "sqlite3", "~> 2.5"
    #   end
    #   appraisal_matrix(rails: "6.0", sidekiq: "5.0") do |rails:, sidekiq:|
    #     if rails < "7"
    #       # do something...
    #     else
    #       # do something else...
    #     end
    #   end
    def appraisal_matrix(**kwargs, &block)
      # names_and_versions_to_test
      # [
      #   [[rails, 6.0], [rails, 6.1], [rails, 7.0], [rails, 7.1]],
      #   [[sidekiq, 1.0], [sidekiq, 2.0]],
      #   [[a, x], [a, y], [a, z]]
      # ]
      names_and_versions_to_test =
        kwargs.map do |gem_name, version_options|
          version_array =
            case version_options
            when String
              parsed_options = version_options.include?(" ") ? [version_options] : [">= #{version_options}"]
              VersionArray.new(gem_name: gem_name, versions: parsed_options)
            when Integer, Float
              VersionArray.new(gem_name: gem_name, versions: [">= #{version_options}"])
            when Array
              VersionArray.new(gem_name: gem_name, versions: version_options)
            when Hash
              VersionArray.new(gem_name: gem_name, **version_options)
            end

          version_array.versions.map do |version|
            [gem_name, version]
          end
        end

      # matrix
      # [
      #   [[rails, 6.0], [sidekiq, 1.0], ...[a, x]]
      #   [[rails, 6.0], [sidekiq, 1.0], ...[a, y]]
      #   [[rails, 6.0], [sidekiq, 1.0], ...[a, z]]
      #   ...
      #   [[rails, 7.1], [sidekiq, 2.0], ...[a, z]]
      # ]
      matrix = names_and_versions_to_test[0].product(*names_and_versions_to_test[1..])

      # Iterate over versions to test and create appraisal per
      matrix.each do |appraisal_spec|
        appraise appraisal_file_name(appraisal_spec) do
          appraisal_spec.each do |gem_name, version|
            gem gem_name, "~> #{version}.0"
          end
          if block
            block_args = appraisal_spec.to_h { |gem_name, version| [gem_name.to_sym, Gem::Version.new(version)] }
            instance_exec(**block_args, &block)
          end
        end
      end
    end

    private

    # [["rails", "6.0"], ["sidekiq", "5"]]
    # => "rails-6_0-sidekiq-5"
    def appraisal_file_name(names_and_versions)
      names_and_versions.map do |name, version|
        "#{name}-#{version.gsub('.', '_')}"
      end.join("-")
    end
  end
end

Appraisal::AppraisalFile.prepend(Appraisal::Matrix::AppraiseFileWithMatrix)
