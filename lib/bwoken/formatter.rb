module Bwoken
  class Formatter

    class << self
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


    %w(pass fail debug other).each do |log_level|
      on log_level.to_sym do |line|
        puts line
      end
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
