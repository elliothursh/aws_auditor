require 'slack-notifier'

module SportNginAwsAuditor
  class NotifySlack
    attr_accessor :text, :channel, :webhook, :username, :icon_url, :icon_emoji

    def initialize(text)
      self.text = text
      self.channel = SportNginAwsAuditor::Config.slack[:channel]
      self.username = SportNginAwsAuditor::Config.slack[:username]
      self.webhook = SportNginAwsAuditor::Config.slack[:webhook]
      self.icon_url = SportNginAwsAuditor::Config.slack[:icon_url]
    end

    def perform
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
