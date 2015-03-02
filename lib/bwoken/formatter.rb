module Bwoken
  class Formatter

    class << self
      def format stdout
        new.format stdout
      end

      def format_build stdout
        new.format_build stdout
      end

      def on name, &block
        define_method "_on_#{name}_callback" do |*line|
          instance_exec(*line, &block)
        end
      end

    end

    def method_missing(method_name, *args, &block)
      callback_method_sig = "_on_#{method_name}_callback"
      if self.respond_to? callback_method_sig.to_sym
        send(callback_method_sig, *args, &block)
      end
    end

    def line_demuxer line, exit_status
      if line =~ /Instruments Trace Error/
        exit_status = 1
        _on_fail_callback(line)
      elsif line =~ /^\d{4}/
        tokens = line.split(' ')

        if tokens[3] =~ /Pass/
          _on_pass_callback(line)
        elsif tokens[3] =~ /Start/
          _on_start_callback(line)
        elsif tokens[3] =~ /Fail/ || line =~ /Script threw an uncaught JavaScript error/
          exit_status = 1
          _on_fail_callback(line)
        elsif tokens[3] =~ /Error/
          _on_error_callback(line)
        else
          _on_debug_callback(line)
        end
      elsif line =~ /Instruments Trace Complete/
        _on_complete_callback(line)
      else
        _on_other_callback(line)
      end
      exit_status
    end

    %w(pass fail debug other).each do |log_level|
      on log_level.to_sym do |line|
        puts line
      end
    end

    def format stdout
      exit_status = 0

      stdout.each_line do |line|
        exit_status = line_demuxer line, exit_status
      end

      exit_status
    end

    def format_build stdout
      out_string = ''
      stdout.each_line do |line|
        out_string << line
        if line.length > 1
          _on_build_line_callback(line)
        end
      end
      out_string
    end

    on :before_build_start do
      puts 'Building'
    end

    on :build_line do |line|
      print '.'
    end

    on :build_successful do |build_log|
      puts
      puts
      puts "### Build Successful ###"
      puts
    end

    on :build_failed do |build_log, error_log|
      puts build_log
      puts "Standard Error:"
      puts error_log
      puts '## Build failed ##'
    end

  end
end
