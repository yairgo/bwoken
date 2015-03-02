require 'spec_helper'
require 'bwoken/formatters/line_demuxer'

describe Bwoken::LineDemuxer do

  describe '#line_demuxer' do
    let(:formatter_one) { double 'format one' }
    let(:formatter_two) { double 'format two' }
    let(:formatters) { [ formatter_one, formatter_two] }

    context 'for a passing line' do
      it 'calls _on_pass_callback and returns correct status' do
        expect_call_with(formatters, :_on_pass_callback, '1234 a a Pass')

        exit_status = subject.demux('1234 a a Pass', 0, formatters)
        expect(exit_status).to eq(0)
      end
    end

    context 'for a failing line' do
      context 'Fail error' do
        it 'calls _on_fail_callback' do
          expect_call_with(formatters, :_on_fail_callback, '1234 a a Fail')
          exit_status = subject.demux('1234 a a Fail', 0, formatters)
          expect(exit_status).to eq(1)
        end
      end

      context 'Instruments Trace Error message' do
        it 'calls _on_fail_callback' do
          msg = 'Instruments Trace Error foo'
          expect_call_with(formatters, :_on_fail_callback, msg)
          exit_status = subject.demux(msg, 0, formatters)
          expect(exit_status).to eq(1)
        end
      end
    end

    context 'for a debug line' do
      it 'calls _on_debug_callback' do
        expect_call_with(formatters, :_on_debug_callback, '1234 a a feh')
        exit_status = subject.demux('1234 a a feh', 0, formatters)
        expect(exit_status).to eq(0)
      end
    end

    context 'for any other line' do
      it 'calls _on_other_callback' do
        expect_call_with(formatters, :_on_other_callback, 'blah blah blah')
        exit_status = subject.demux('blah blah blah', 0, formatters)
        expect(exit_status).to eq(0)
      end
    end
  end

  def expect_call_with(formatters, method, args)
    formatters.each do |f|
     f.should_receive(method).with(args)
    end
  end
end
