require 'spec_helper'

require 'bwoken/cli/test'

describe Bwoken::CLI::Test do

  describe '#init' do
    let(:options) { { simulator: true } }

    subject { described_class.new(options) }
    context 'formatters' do

      context 'when verbose' do
        before do
          options[:verbose] = true
        end

        it 'should use passthru' do
          expect(formatters.length).to be(1)
          expect(formatters.first).to be_kind_of(Bwoken::PassthruFormatter)
        end
      end

      context 'not verbose' do
        context 'when colorful' do
          before do
            options[:formatter] = 'colorful'
          end

          it 'should use colorful' do
            expect(formatters.length).to be(1)
            expect(formatters.first).to be_kind_of(Bwoken::ColorfulFormatter)
          end
        end

        context 'when passthru' do
          before do
            options[:formatter] = 'passthru'
          end

          it 'should use passthru' do
            expect(formatters.length).to be(1)
            expect(formatters.first).to be_kind_of(Bwoken::PassthruFormatter)
          end
        end
      end

      context 'when junit' do
        before do
          options[:junit] = true
        end

        it 'should use passthru' do
          expect(formatters.length).to be(2)
          expect(formatters.last).to be_kind_of(Bwoken::JUnitFormatter)
        end
      end
    end
  end

  def formatters
    subject.options[:formatter].recipients
  end

end
