require 'slack-notifier'

module AwsAuditor
  class NotifySlack
    attr_accessor :text, :channel, :username, :icon_url, :icon_emoji

    CHANNEL = AwsAuditor::Config.slack[:channel]
    USERNAME = AwsAuditor::Config.slack[:username]
    WEBHOOK_URL = AwsAuditor::Config.slack[:webhook]
    ICON_URL = AwsAuditor::Config.slack[:icon_url]

    def initialize(text)
      self.text = text
      self.channel = CHANNEL
      self.username = USERNAME
    end

    def perform
      options = {webhook_url: WEBHOOK_URL,
                 channel: CHANNEL,
                 username: USERNAME,
                 icon_url: ICON_URL,
                 http_options: {open_timeout: 10}
                }
      Slack::Notifier.new(WEBHOOK_URL, options).ping(text)
    end
  end
end
