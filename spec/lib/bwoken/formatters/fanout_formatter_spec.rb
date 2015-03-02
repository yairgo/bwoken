require 'spec_helper'
require 'bwoken/formatters/fanout_formatter'

describe Bwoken::FanoutFormatter do

  let(:line_demuxer) { double 'line_demuxer' }
  let(:recipients) { [ formatter ] }
  let(:formatter) { double 'formatter' }
  subject{ described_class.new(line_demuxer) }
  before do
    subject.add_recipient(formatter)
  end

  describe '#format' do
    it 'calls the demuxer for each line' do
      line_demuxer.should_receive(:demux).exactly(3).times
      subject.format("a\nb\nc")
    end

    context 'when no lines fail' do
      it 'returns 0' do
        line_demuxer.should_receive(:demux).with("a\n", 0, recipients).ordered.and_return(0)
        line_demuxer.should_receive(:demux).with("b\n", 0, recipients).ordered.and_return(0)
        line_demuxer.should_receive(:demux).with("c", 0, recipients).ordered.and_return(0)
        subject.format("a\nb\nc").should == 0
      end
    end

    context 'when any line fails' do
      it 'returns 1' do
        line_demuxer.should_receive(:demux).with("a\n", 0, recipients).ordered.and_return(0)
        line_demuxer.should_receive(:demux).with("b\n", 0, recipients).ordered.and_return(1)
        line_demuxer.should_receive(:demux).with("c", 1, recipients).ordered.and_return(1)
        subject.format("a\nb\nc").should == 1
      end
    end
  end

  describe '#format_build' do
    it 'sends output lines to recpients' do
      formatter.should_receive(:_on_build_line_callback).with("a\n")
      formatter.should_receive(:_on_build_line_callback).with("b\n")
      formatter.should_receive(:_on_build_line_callback).with("c\n")

      subject.format_build("a\nb\nc\n")
    end

    it 'ignores empty lines' do
      formatter.should_receive(:_on_build_line_callback).exactly(0).times
      subject.format_build("\n\n\n")
    end

    it 'returns the passed in build text' do
      formatter.stub(:_on_build_line_callback)
      build_text = subject.format_build("a\nb\nc\n")
      build_text.should == "a\nb\nc\n"
    end

  end

  describe '#build_successful build_log' do
    it 'displays build successful' do
      formatter.should_receive(:_on_build_successful_callback).with('foo')
      subject.build_successful('foo')
    end

  end

  describe '#build_failed build_log, error_log' do
    it 'displays the build_log' do
      formatter.should_receive(:_on_build_failed_callback).with('build', 'bar')
      subject.build_failed('build', 'bar')
    end
  end

end
