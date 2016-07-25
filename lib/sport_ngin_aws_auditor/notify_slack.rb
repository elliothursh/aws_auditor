require 'httparty'

module SportNginAwsAuditor
  class NotifySlack
    attr_accessor :text, :channel, :webhook, :username, :icon_url, :icon_emoji, :attachments

    def initialize(text)
      self.text = text
      self.attachments = []
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
        options = {text: text,
                   webhook: webhook,
                   channel: channel,
                   username: username,
                   icon_url: icon_url,
                   attachments: attachments
                  }
        HTTParty.post(options[:webhook], :body => "payload=#{options.to_json}")
      end
    end
  end
end
