module Bwoken
  class LineDemuxer

    def demux(line, exit_status, recipients)
      if line =~ /Instruments Trace Error/
        exit_status = 1
        message = '_on_fail_callback'
        #_on_fail_callback(line)
      elsif line =~ /^\d{4}/
        tokens = line.split(' ')

        if tokens[3] =~ /Pass/
          message = '_on_pass_callback'
        elsif tokens[3] =~ /Start/
          message = '_on_start_callback'
        elsif tokens[3] =~ /Fail/ || line =~ /Script threw an uncaught JavaScript error/
          exit_status = 1
          message = '_on_fail_callback'
        elsif tokens[3] =~ /Error/
          message = '_on_error_callback'
        else
          message = '_on_debug_callback'
        end
      elsif line =~ /Instruments Trace Complete/
        message = '_on_complete_callback'
      else
        message = '_on_other_callback'
      end

      send_to_recipients(recipients, message, line)
      exit_status
    end

    def send_to_recipients(recipients, message, line)
      message = message.to_sym
      recipients.each do |recipient|
        recipient.send(message, *line) if recipient.respond_to?(message)
      end
    end
  end
end
