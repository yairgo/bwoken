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
          expect(formatters).to be_kind_of(Bwoken::PassthruFormatter)
        end
      end

      context 'not verbose' do
        context 'when colorful' do
          before do
            options[:formatter] = 'colorful'
          end

          it 'should use colorful' do
            expect(formatters).to be_kind_of(Bwoken::ColorfulFormatter)
          end
        end

        context 'when passthru' do
          before do
            options[:formatter] = 'passthru'
          end

          it 'should use passthru' do
            expect(formatters).to be_kind_of(Bwoken::PassthruFormatter)
          end
        end
      end

    end
  end

  def formatters
    subject.options[:formatter]
  end

end
