require 'slack-notifier'

module AwsAuditor
  class NotifySlack
    attr_accessor :text, :channel, :webhook, :username, :icon_url, :icon_emoji

    def initialize(text)
      self.text = text
      self.channel = AwsAuditor::Config.slack[:channel]
      self.username = AwsAuditor::Config.slack[:username]
      self.webhook = AwsAuditor::Config.slack[:webhook]
      self.icon_url = AwsAuditor::Config.slack[:icon_url]
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
