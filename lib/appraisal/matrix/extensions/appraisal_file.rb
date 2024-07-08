# frozen_string_literal: true

require 'appraisal'
require 'appraisal/matrix/rubygems_helper'

module Appraisal::Matrix
  module AppraiseFileWithMatrix

    class VersionArray
      include RubygemsHelper

      SUPPORTED_VERSION_STEPS = [:major, :minor, :patch].freeze

      attr_reader :gem_name, :minimum_version, :maximum_version, :step

      def initialize(gem_name:, min:, max: nil, step: :minor)
        SUPPORTED_VERSION_STEPS.include?(step) or raise("Unsupported version step: #{step}")

        @gem_name = gem_name
        @minimum_version = Gem::Version.new(min)
        @maximum_version = max ? Gem::Version.new(max) : nil
        @step = step.to_sym
      end

      def versions
        versions_to_test(gem_name, minimum_version, maximum_version, step)
      end
    end

    # appraisal_matrix(rails: "6.0")
    # appraisal_matrix(rails: "6.0", sidekiq: "5")
    # appraisal_matrix(rails: "6.0", sidekiq: { min: “5.0”, max: “6.0”, step: :major })
    # appraisal_matrix(rails: "6.0") do
    #   gem "sqlite3", "~> 2.5"
    # end
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
            if version_options.is_a?(Hash)
              VersionArray.new(gem_name:, **version_options)
            else
              VersionArray.new(gem_name:, min: version_options)
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
          instance_eval(&block) if block
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
