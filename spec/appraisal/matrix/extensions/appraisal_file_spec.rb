# frozen_string_literal: true

require_relative "../../../../lib/appraisal/matrix/extensions/appraisal_file"

RSpec.describe Appraisal::Matrix::AppraiseFileWithMatrix do
  include Appraisal::Matrix::AppraiseFileWithMatrix

  describe "#appraisal_matrix" do
    subject { appraisal_matrix(**desired_gems) }

    context "with a maximum version specified" do
      let(:desired_gems) { { rails: { min: "6.1", max: "7.0" } } }

      it "is not implemented yet" do
        expect { subject }.to raise_error("TODO: Version request options not implemented yet")
      end
    end

    context "with a step specified" do
      let(:desired_gems) { { rails: { min: "6.1", step: :major } } }

      it "is not implemented yet" do
        expect { subject }.to raise_error("TODO: Version request options not implemented yet")
      end
    end

    context "for a single gem" do
      let(:desired_gems) { { rails: "6.1" } }

      before do
        allow(self).to receive(:versions_to_test) { ["6.1", "7.0", "7.1"] }
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
        allow(self).to receive(:versions_to_test).with(:rails, Gem::Version.new("6.1")).and_return(["6.1", "7.0", "7.1"])
        allow(self).to receive(:versions_to_test).with(:sidekiq, Gem::Version.new("5")).and_return(["5.0", "6.0"])
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
