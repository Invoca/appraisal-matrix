# frozen_string_literal: true

require_relative "../../../../lib/appraisal/matrix/extensions/appraisal_file"

RSpec.describe Appraisal::Matrix::AppraiseFileWithMatrix do
  include Appraisal::Matrix::AppraiseFileWithMatrix

  describe "#appraisal_matrix" do
    subject { appraisal_matrix(**desired_gems) }

    context "with a maximum version specified" do
      let(:desired_gems) { { rails: { min: "6.1", max: "7.1" } } }

      before do
        expect(Appraisal::Matrix::AppraiseFileWithMatrix::VersionArray).to receive(:new).with(min: "6.1", max: "7.1").and_wrap_original do |original_method, *args|
          original_method.call(*args).tap do |version_array|
            expect(version_array).to receive(:versions_to_test).with(:rails, Gem::Version.new("6.1"), Gem::Version.new("7.1"), :minor).and_return(["6.1", "7.0"])
          end
        end
      end

      it "creates a matrix of appraisals" do
        expect(self).to receive(:appraise).with("rails-6_1").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.0") }
        expect(self).to receive(:appraise).with("rails-7_0").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 7.0.0") }
        subject
      end
    end

    context "requesting major version steps" do
      let(:desired_gems) { { rails: { min: "6.1", step: :major } } }

      before do
        expect(Appraisal::Matrix::AppraiseFileWithMatrix::VersionArray).to receive(:new).with(min: "6.1", step: :major).and_wrap_original do |original_method, *args|
          original_method.call(*args).tap do |version_array|
            expect(version_array).to receive(:versions_to_test).with(:rails, Gem::Version.new("6.1"), nil, :major).and_return(["6", "7"])
          end
        end
      end

      it "creates a matrix of appraisals" do
        expect(self).to receive(:appraise).with("rails-6").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 6.0") }
        expect(self).to receive(:appraise).with("rails-7").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 7.0") }
        subject
      end
    end

    context "requesting patch version steps" do
      let(:desired_gems) { { rails: { min: "6.1", step: :patch } } }

      before do
        expect(Appraisal::Matrix::AppraiseFileWithMatrix::VersionArray).to receive(:new).with(min: "6.1", step: :patch).and_wrap_original do |original_method, *args|
          original_method.call(*args).tap do |version_array|
            expect(version_array).to receive(:versions_to_test).with(:rails, Gem::Version.new("6.1"), nil, :patch).and_return(["6.1.0", "6.1.1", "7.0.0", "7.1.0"])
          end
        end
      end

      it "creates a matrix of appraisals" do
        expect(self).to receive(:appraise).with("rails-6_1_0").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.0.0") }
        expect(self).to receive(:appraise).with("rails-6_1_1").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.1.0") }
        expect(self).to receive(:appraise).with("rails-7_0_0").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 7.0.0.0") }
        expect(self).to receive(:appraise).with("rails-7_1_0").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 7.1.0.0") }
        subject
      end
    end

    context "requesting a step that is not supported" do
      let(:desired_gems) { { rails: { min: "6.1", step: :pizza } } }

      it "raises an error" do
        expect { subject }.to raise_error("Unsupported version step: pizza")
      end
    end

    context "for a single gem" do
      let(:desired_gems) { { rails: "6.1" } }

      before do
        expect(Appraisal::Matrix::AppraiseFileWithMatrix::VersionArray).to receive(:new).with(min: "6.1").and_wrap_original do |original_method, *args|
          original_method.call(*args).tap do |version_array|
            expect(version_array).to receive(:versions_to_test).with(:rails, Gem::Version.new("6.1"), nil, :minor).and_return(["6.1", "7.0", "7.1"])
          end
        end
      end

      it "creates a matrix of appraisals including the specified minimum version" do
        expect(self).to receive(:appraise).with("rails-6_1").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.0") }
        expect(self).to receive(:appraise).with("rails-7_0").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 7.0.0") }
        expect(self).to receive(:appraise).with("rails-7_1").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 7.1.0") }
        subject
      end

      context "with a block to pass into each appraisal" do
        it "yields the block to each appraisal" do
          expect(self).to receive(:appraise).with("rails-6_1").and_yield do |block_scope|
            expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.0")
            expect(block_scope).to receive(:gem).with("sqlite3", "~> 2.5")
          end
          expect(self).to receive(:appraise).with("rails-7_0").and_yield do |block_scope|
            expect(block_scope).to receive(:gem).with(:rails, "~> 7.0.0")
            expect(block_scope).to receive(:gem).with("sqlite3", "~> 2.5")
          end
          expect(self).to receive(:appraise).with("rails-7_1").and_yield do |block_scope|
            expect(block_scope).to receive(:gem).with(:rails, "~> 7.1.0")
            expect(block_scope).to receive(:gem).with("sqlite3", "~> 2.5")
          end

          appraisal_matrix(**desired_gems) { gem "sqlite3", "~> 2.5" }
        end
      end
    end

    context "for multiple gems" do
      let(:desired_gems) { { rails: "6.1", sidekiq: "5" } }

      before do
        expect(Appraisal::Matrix::AppraiseFileWithMatrix::VersionArray).to receive(:new).with(min: "6.1").and_wrap_original do |original_method, *args|
          original_method.call(*args).tap do |version_array|
            expect(version_array).to receive(:versions_to_test).with(:rails, Gem::Version.new("6.1"), nil, :minor).and_return(["6.1", "7.0", "7.1"])
          end
        end

        expect(Appraisal::Matrix::AppraiseFileWithMatrix::VersionArray).to receive(:new).with(min: "5").and_wrap_original do |original_method, *args|
          original_method.call(*args).tap do |version_array|
            expect(version_array).to receive(:versions_to_test).with(:sidekiq, Gem::Version.new("5"), nil, :minor).and_return(["5.0", "6.0"])
          end
        end
      end

      it "creates a matrix of appraisals including the specified minimum version" do
        expect(self).to receive(:appraise).with("rails-6_1-sidekiq-5_0").and_yield do |block_scope|
          expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.0")
          expect(block_scope).to receive(:gem).with(:sidekiq, "~> 5.0.0")
        end
        expect(self).to receive(:appraise).with("rails-6_1-sidekiq-6_0").and_yield do |block_scope|
          expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.0")
          expect(block_scope).to receive(:gem).with(:sidekiq, "~> 6.0.0")
        end
        expect(self).to receive(:appraise).with("rails-7_0-sidekiq-5_0").and_yield do |block_scope|
          expect(block_scope).to receive(:gem).with(:rails, "~> 7.0.0")
          expect(block_scope).to receive(:gem).with(:sidekiq, "~> 5.0.0")
        end
        expect(self).to receive(:appraise).with("rails-7_0-sidekiq-6_0").and_yield do |block_scope|
          expect(block_scope).to receive(:gem).with(:rails, "~> 7.0.0")
          expect(block_scope).to receive(:gem).with(:sidekiq, "~> 6.0.0")
        end
        expect(self).to receive(:appraise).with("rails-7_1-sidekiq-5_0").and_yield do |block_scope|
          expect(block_scope).to receive(:gem).with(:rails, "~> 7.1.0")
          expect(block_scope).to receive(:gem).with(:sidekiq, "~> 5.0.0")
        end
        expect(self).to receive(:appraise).with("rails-7_1-sidekiq-6_0").and_yield do |block_scope|
          expect(block_scope).to receive(:gem).with(:rails, "~> 7.1.0")
          expect(block_scope).to receive(:gem).with(:sidekiq, "~> 6.0.0")
        end
        subject
      end
    end
  end
end
