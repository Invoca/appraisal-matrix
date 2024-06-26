# frozen_string_literal: true

require 'json'
require 'open-uri'

module Appraisal
  module Matrix
    module RubygemsHelper
      def versions_to_test(gem_name, minimum_version)
        # Generate a set to store the versions to test against 
        versions_to_test = Set.new

        # Load versions from rubygems api
        URI.parse("https://rubygems.org/api/v1/versions/#{gem_name}.json").open do |raw_version_data|
          JSON.parse(raw_version_data.read).each do |version_data|
            version = Gem::Version.new(version_data['number'])
            versions_to_test << version.segments[0..1].join('.') if version >= minimum_version && !version.prerelease?
          end
        end

        versions_to_test
      end
    end
  end
end
