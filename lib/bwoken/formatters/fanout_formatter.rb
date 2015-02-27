module Bwoken
  # Forwards any messages sent to this object to all recipients
  # that respond to that message.
  class FanoutFormatter < BasicObject
    attr_reader :recipients

    def initialize
      @recipients = []
    end

    def add_recipient(recipient)
      recipients << recipient
    end

    def method_missing(message, *args)
      recipients.each do |recipient|
        recipient.send(message, *args) if recipient.respond_to?(message)
      end
    end
  end

end
