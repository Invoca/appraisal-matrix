# frozen_string_literal: true

require 'appraisal'
require 'appraisal/matrix/rubygems_helper'

module Appraisal::Matrix
  module AppraiseFileWithMatrix
    include RubygemsHelper

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
        kwargs.map do |gem_name, version_request|
          if version_request.is_a?(Hash)
            raise "TODO: Version request options not implemented yet"
          else
            minimum_version = Gem::Version.new(version_request)
          end

          versions_to_test(gem_name, minimum_version).map do |version|
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
