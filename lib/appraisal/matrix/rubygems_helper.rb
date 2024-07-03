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
            versions_to_test << version_segments(version, step).join('.') if include_version?(version, minimum_version, maximum_version)
          end
        end

        versions_to_test
      end

      private

      def version_segments(version, step)
        case step
        when :major
          version.segments[0..0]
        when :minor
          version.segments[0..1]
        when :patch
          version.segments[0..2]
        else
          raise "Unsupported requested version step: #{step}"
        end
      end

      def include_version?(version, minimum_version, maximum_version)
        if maximum_version
          !version.prerelease? && version >= minimum_version && version < maximum_version
        else
          !version.prerelease? && version >= minimum_version
        end
      end
    end
  end
end
