require 'httparty'

module SportNginAwsAuditor
  class NotifySlack
    attr_accessor :text, :channel, :webhook, :username, :icon_url, :icon_emoji, :attachments, :config_hash

    def initialize(text, config)
      self.text = text
      self.attachments = []
      self.config_hash = eval(config) if config

      if SportNginAwsAuditor::Config.slack
        self.channel = SportNginAwsAuditor::Config.slack[:channel]
        self.username = SportNginAwsAuditor::Config.slack[:username]
        self.webhook = SportNginAwsAuditor::Config.slack[:webhook]
        self.icon_url = SportNginAwsAuditor::Config.slack[:icon_url]
      elsif self.config_hash
        self.channel = self.config_hash[:slack][:channel]
        self.username = self.config_hash[:slack][:username]
        self.webhook = self.config_hash[:slack][:webhook]
        self.icon_url = self.config_hash[:slack][:icon_url]
      else
        puts "To use Slack, you must provide either a separate config file or a hash of config data. See the README for more information."
      end
    end

    def perform
      if SportNginAwsAuditor::Config.slack || config_hash
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
