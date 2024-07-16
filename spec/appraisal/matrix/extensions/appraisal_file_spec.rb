# frozen_string_literal: true

require_relative "../../../../lib/appraisal/matrix/extensions/appraisal_file"

RSpec.describe Appraisal::Matrix::AppraiseFileWithMatrix do
  include Appraisal::Matrix::AppraiseFileWithMatrix

  describe "#appraisal_matrix" do
    subject { appraisal_matrix(**desired_gems) }

    context "with a maximum version specified" do
      before do
        expect(Appraisal::Matrix::RubygemsHelper).to receive(:versions_to_test).with(:rails, Gem::Requirement.new([">= 6.1", "< 7.1"]), :minor).and_return(["6.1", "7.0"])
      end

      context "using the keyword argument syntax" do
        let(:desired_gems) { { rails: { versions: [">= 6.1", "< 7.1"] } } }

        it "creates a matrix of appraisals" do
          expect(self).to receive(:appraise).with("rails-6_1").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.0") }
          expect(self).to receive(:appraise).with("rails-7_0").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 7.0.0") }
          subject
        end
      end

      context "using the array argument syntax" do
        let (:desired_gems) { { rails: [">= 6.1", "< 7.1"] } }

        it "creates a matrix of appraisals" do
          expect(self).to receive(:appraise).with("rails-6_1").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.0") }
          expect(self).to receive(:appraise).with("rails-7_0").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 7.0.0") }
          subject
        end
      end
    end

    context "requesting major version steps" do
      let(:desired_gems) { { rails: { versions: [">= 6.1"], step: :major } } }

      before do
        expect(Appraisal::Matrix::RubygemsHelper).to receive(:versions_to_test).with(:rails, Gem::Requirement.new([">= 6.1"]), :major).and_return(["6", "7"])
      end

      it "creates a matrix of appraisals" do
        expect(self).to receive(:appraise).with("rails-6").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 6.0") }
        expect(self).to receive(:appraise).with("rails-7").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 7.0") }
        subject
      end
    end

    context "requesting patch version steps" do
      let(:desired_gems) { { rails: { versions: [">= 6.1"], step: :patch } } }

      before do
        expect(Appraisal::Matrix::RubygemsHelper).to receive(:versions_to_test).with(:rails, Gem::Requirement.new([">= 6.1"]), :patch).and_return(["6.1.0", "6.1.1", "7.0.0", "7.1.0"])
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
      let(:desired_gems) { { rails: { versions: [">= 6.1"], step: :pizza } } }

      it "raises an error" do
        expect { subject }.to raise_error("Unsupported version step: pizza")
      end
    end

    context "default behavior for a single gem" do
      shared_examples "a matrix of appraisals" do
        it "creates a matrix of appraisals including the specified minimum version" do
          expect(self).to receive(:appraise).with("rails-6_1").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.0") }
          expect(self).to receive(:appraise).with("rails-7_0").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 7.0.0") }
          expect(self).to receive(:appraise).with("rails-7_1").and_yield { |block_scope| expect(block_scope).to receive(:gem).with(:rails, "~> 7.1.0") }
          subject
        end
      end

      before do
        expect(Appraisal::Matrix::RubygemsHelper).to receive(:versions_to_test).with(:rails, expected_version_requirement, :minor).and_return(["6.1", "7.0", "7.1"])
      end

      let(:expected_version_requirement) { Gem::Requirement.new([">= 6.1"]) }

      context "as a string" do
        let(:desired_gems) { { rails: "6.1" } }

        it_behaves_like "a matrix of appraisals"
      end

      context "with a block to pass into each appraisal" do
        subject(:run_matrix) do
          appraisal_matrix(**desired_gems) { gem "sqlite3", "~> 2.5" }
        end
        let(:desired_gems) { { rails: "6.1" } }

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

          run_matrix
        end

        context "with a block with arguments" do
          subject(:run_matrix) do
            appraisal_matrix(**desired_gems) do |rails:|
              if rails < Gem::Version.new("7")
                gem "sqlite3", "< 2"
              else
                gem "sqlite3", "~> 2.5"
              end
            end
          end

          it "yields the block with the versions to each appraisal" do
            expect(self).to receive(:appraise).with("rails-6_1").and_yield do |block_scope|
              expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.0")
              expect(block_scope).to receive(:gem).with("sqlite3", "< 2")
            end
            expect(self).to receive(:appraise).with("rails-7_0").and_yield do |block_scope|
              expect(block_scope).to receive(:gem).with(:rails, "~> 7.0.0")
              expect(block_scope).to receive(:gem).with("sqlite3", "~> 2.5")
            end
            expect(self).to receive(:appraise).with("rails-7_1").and_yield do |block_scope, versions|
              expect(block_scope).to receive(:gem).with(:rails, "~> 7.1.0")
              expect(block_scope).to receive(:gem).with("sqlite3", "~> 2.5")
            end

            run_matrix
          end
        end
      end

      context "as a string with an operator provided" do
        let(:desired_gems) { { rails: ">= 6.1" } }

        it_behaves_like "a matrix of appraisals"
      end

      context "as a Float" do
        let(:desired_gems) { { rails: 6.1 } }

        it_behaves_like "a matrix of appraisals"
      end

      context "as an Integer" do
        let(:desired_gems) { { rails: 6 } }
        let(:expected_version_requirement) { Gem::Requirement.new([">= 6"]) }

        it_behaves_like "a matrix of appraisals"
      end
    end

    context "for multiple gems" do
      let(:desired_gems) { { rails: "6.1", sidekiq: "5" } }

      before do
        expect(Appraisal::Matrix::RubygemsHelper).to receive(:versions_to_test).with(:rails, Gem::Requirement.new([">= 6.1"]), :minor).and_return(["6.1", "7.0", "7.1"])
        expect(Appraisal::Matrix::RubygemsHelper).to receive(:versions_to_test).with(:sidekiq, Gem::Requirement.new([">= 5"]), :minor).and_return(["5.0", "6.0"])
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

      context "with a block" do
        subject(:run_matrix) do
          appraisal_matrix(**desired_gems) do |rails:, sidekiq:|
            if rails < Gem::Version.new("7") && sidekiq < Gem::Version.new("6")
              gem "sqlite3", "< 2"
            else
              gem "sqlite3", "~> 2.5"
            end
          end
        end

        it "yields the block with the versions to each appraisal" do
          expect(self).to receive(:appraise).with("rails-6_1-sidekiq-5_0").and_yield do |block_scope|
            expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.0")
            expect(block_scope).to receive(:gem).with(:sidekiq, "~> 5.0.0")
            expect(block_scope).to receive(:gem).with("sqlite3", "< 2")
          end
          expect(self).to receive(:appraise).with("rails-6_1-sidekiq-6_0").and_yield do |block_scope|
            expect(block_scope).to receive(:gem).with(:rails, "~> 6.1.0")
            expect(block_scope).to receive(:gem).with(:sidekiq, "~> 6.0.0")
            expect(block_scope).to receive(:gem).with("sqlite3", "~> 2.5")
          end
          expect(self).to receive(:appraise).with("rails-7_0-sidekiq-5_0").and_yield do |block_scope|
            expect(block_scope).to receive(:gem).with(:rails, "~> 7.0.0")
            expect(block_scope).to receive(:gem).with(:sidekiq, "~> 5.0.0")
            expect(block_scope).to receive(:gem).with("sqlite3", "~> 2.5")
          end
          expect(self).to receive(:appraise).with("rails-7_0-sidekiq-6_0").and_yield do |block_scope|
            expect(block_scope).to receive(:gem).with(:rails, "~> 7.0.0")
            expect(block_scope).to receive(:gem).with(:sidekiq, "~> 6.0.0")
            expect(block_scope).to receive(:gem).with("sqlite3", "~> 2.5")
          end
          expect(self).to receive(:appraise).with("rails-7_1-sidekiq-5_0").and_yield do |block_scope|
            expect(block_scope).to receive(:gem).with(:rails, "~> 7.1.0")
            expect(block_scope).to receive(:gem).with(:sidekiq, "~> 5.0.0")
            expect(block_scope).to receive(:gem).with("sqlite3", "~> 2.5")
          end
          expect(self).to receive(:appraise).with("rails-7_1-sidekiq-6_0").and_yield do |block_scope|
            expect(block_scope).to receive(:gem).with(:rails, "~> 7.1.0")
            expect(block_scope).to receive(:gem).with(:sidekiq, "~> 6.0.0")
            expect(block_scope).to receive(:gem).with("sqlite3", "~> 2.5")
          end
          run_matrix
        end
      end
    end
  end
end
