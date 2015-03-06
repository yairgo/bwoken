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

  end
end
