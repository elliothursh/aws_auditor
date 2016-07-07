require 'slack-notifier'

module SportNginAwsAuditor
  class NotifySlack
    attr_accessor :text, :channel, :webhook, :username, :icon_url, :icon_emoji

    def initialize(text)
      self.text = text
      if SportNginAwsAuditor::Config.slack
        self.channel = SportNginAwsAuditor::Config.slack[:channel]
        self.username = SportNginAwsAuditor::Config.slack[:username]
        self.webhook = SportNginAwsAuditor::Config.slack[:webhook]
        self.icon_url = SportNginAwsAuditor::Config.slack[:icon_url]
      else
        puts "To use Slack, you must provide a separate config file. See the README for more information."
      end
    end

    def perform
      if SportNginAwsAuditor::Config.slack
        options = {webhook: webhook,
                   channel: channel,
                   username: username,
                   icon_url: icon_url,
                   http_options: {open_timeout: 10}
                  }
        Slack::Notifier.new(webhook, options).ping(text)
      end
    end
  end
end
