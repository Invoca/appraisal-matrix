# frozen_string_literal: true

require 'json'
require 'open-uri'

module Appraisal
  module Matrix
    module RubygemsHelper
      def versions_to_test(gem_name, minimum_version, maximum_version, step)
        # Generate a set to store the versions to test against 
        versions_to_test = Set.new

        # Load versions from rubygems api
        URI.parse("https://rubygems.org/api/v1/versions/#{gem_name}.json").open do |raw_version_data|
          JSON.parse(raw_version_data.read).each do |version_data|
            version = Gem::Version.new(version_data['number'])
            versions_to_test << version_for_step(version, step) if include_version?(version, minimum_version, maximum_version)
          end
        end

        versions_to_test
      end

      private

      SEGMENT_STEP_SIZES = {
        major: 1,
        minor: 2,
        patch: 3
      }.freeze

      def version_for_step(version, step)
        size_for_step = SEGMENT_STEP_SIZES[step] or raise ArgumentError, "unsupported requested version step: #{step}, expected #{SEGMENT_STEP_SIZES.keys}"
        version.segments.first(size_for_step).join(".")
      end

      def include_version?(version, minimum_version, maximum_version)
        !version.prerelease? && version >= minimum_version && (!maximum_version || version < maximum_version)
      end
    end
  end
end
