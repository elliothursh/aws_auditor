require 'highline'

module SportNginAwsAuditor
  module Output
    def self.terminal
      @terminal ||= HighLine.new
    end

    def self.ask(*args, &block)
      terminal.ask(*args, &block)
    end

    def self.say(msg)
      terminal.say(msg)
    end
  end
end
