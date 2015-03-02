module Bwoken

  # Forwards any messages sent to this object to all recipients
  # that respond to that message.
  class FanoutFormatter < BasicObject
    attr_reader :recipients
    attr_reader :line_demuxer

    def initialize(line_demuxer = LineDemuxer.new)
      @recipients = []
      @line_demuxer = line_demuxer
    end

    def add_recipient(recipient)
      recipients << recipient
    end

    def format stdout
      exit_status = 0

      stdout.each_line do |line|
        exit_status = @line_demuxer.demux(line, exit_status, recipients)
      end

      exit_status
    end

    def format_build stdout
      out_string = ''
      stdout.each_line do |line|
        out_string << line
        if line.length > 1
          send_to_recipients('_on_build_line_callback', line)
        end
      end
      out_string
    end

    def before_script_run(path)
      send_to_recipients('_on_before_script_run_callback', path)
    end

    def after_script_run
      send_to_recipients('_on_after_script_run_callback')
    end

    def before_build_start
      send_to_recipients('_on_before_build_start_callback')
    end

    def build_successful(line)
      send_to_recipients('_on_build_successful_callback', line)
    end

    def build_failed(build_log, error_log)
      send_to_recipients('_on_build_failed_callback', *[build_log, error_log])
    end

    def send_to_recipients(message, *line)
      message = message.to_sym
      recipients.each do |recipient|
        recipient.send(message, *line) if recipient.respond_to?(message)
      end
    end

    def to_s

    end
  end

end
