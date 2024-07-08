# frozen_string_literal: true

require_relative "../../../lib/appraisal/matrix/rubygems_helper"

RSpec.describe Appraisal::Matrix::RubygemsHelper do
  describe "#versions_to_test" do
    subject { described_class.versions_to_test(gem_name, version_restrictions, step) }

    let(:gem_name)             { "rails" }
    let(:version_restrictions) { [Gem::Dependency.new('', '>= 6.0')] }
    let(:step)                 { :minor }
    
    let(:parsed_uri) { double("uri") }
    let(:raw_version_data) do
      double(
        "raw_version_data",
        read: JSON.dump([
          { "number" => "5.1.5" },
          { "number" => "6.0.0.rc.1" },
          { "number" => "6.0.0" },
          { "number" => "6.1.0" },
          { "number" => "6.1.1" },
          { "number" => "7.0.0.rc.1" },
          { "number" => "7.0.0" },
          { "number" => "7.1.0" },
          { "number" => "7.1.1" }
        ])
      )
    end

    before do
      allow(URI).to receive(:parse).with("https://rubygems.org/api/v1/versions/#{gem_name}.json").and_return(parsed_uri)
      allow(parsed_uri).to receive(:open).and_yield(raw_version_data)
    end

    it { is_expected.to eq(Set.new(["6.0", "6.1", "7.0", "7.1"])) }

    context "when a maximum version is specified" do
      let(:version_restrictions) { [Gem::Dependency.new('', '>= 6.0'), Gem::Dependency.new('', '< 7.0')] }

      it { is_expected.to eq(Set.new(["6.0", "6.1"])) }
    end

    context "when the step is :major" do
      let(:step) { :major }

      it { is_expected.to eq(Set.new(["6", "7"])) }
    end

    context "when the step is :patch" do
      let(:step) { :patch }

      it { is_expected.to eq(Set.new(["6.0.0", "6.1.0", "6.1.1", "7.0.0", "7.1.0", "7.1.1"])) }
    end

    context "when the step is anything else" do
      let(:step) { :pizza }

      it "raises an error" do
        expect { subject }.to raise_error("unsupported requested version step: pizza, expected [:major, :minor, :patch]")
      end
    end
  end
end
