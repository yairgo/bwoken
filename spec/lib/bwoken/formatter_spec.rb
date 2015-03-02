require 'spec_helper'
require 'bwoken/formatter'

describe Bwoken::Formatter do

  describe '.on' do
    let(:klass) { klass = Class.new(Bwoken::Formatter) }
    it 'defines an appropriately named instance method' do
      klass.on(:foo) {|line| ''}
      klass.new.should respond_to('_on_foo_callback')
    end

    it 'defines the instance method with the passed-in block' do
      klass.on(:bar) {|line| 42 }
      klass.new._on_bar_callback('').should == 42
    end
  end

  describe 'default log_level formatters' do
    %w(pass fail debug other).each do |log_level|
      specify "for #{log_level} outputs the passed-in line" do
        formatter = Bwoken::Formatter.new
        out = capture_stdout do
          formatter.send("_on_#{log_level}_callback", "- #{log_level}")
        end
        out.should == "- #{log_level}\n"
      end
    end
  end

  it '#_on_build_line_callback' do
    out = capture_stdout do
      subject._on_build_line_callback("a\n")
    end
    out.should == '.'
  end

  it '#_on_build_successful_callback' do
    out = capture_stdout do
      subject.build_successful('foo')
    end
    out.should == "\n\n### Build Successful ###\n\n"
  end

  describe '#_on_build_failed_callback' do
    it 'displays the build_log' do
      out = capture_stdout do
        subject._on_build_failed_callback('build', 'bar')
      end
      out.should =~ /build/
    end

    it 'displays the error_log' do
      out = capture_stdout do
        subject._on_build_failed_callback('foo', 'error')
      end
      out.should =~ /error/
    end

  end

end
