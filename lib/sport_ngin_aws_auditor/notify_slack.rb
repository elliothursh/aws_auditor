require 'httparty'

module SportNginAwsAuditor
  class NotifySlack
    attr_accessor :text, :channel, :webhook, :username, :icon_url, :icon_emoji, :attachments, :config_hash

    def initialize(text, config_hash)
      self.text = text
      self.attachments = []
      self.config_hash = eval(config_hash) if config_hash

      if SportNginAwsAuditor::Config.slack
        self.channel = SportNginAwsAuditor::Config.slack[:channel]
        self.username = SportNginAwsAuditor::Config.slack[:username]
        self.webhook = SportNginAwsAuditor::Config.slack[:webhook]
        self.icon_url = SportNginAwsAuditor::Config.slack[:icon_url]
      elsif config_hash
        self.channel = config_hash[:slack][:channel]
        self.username = config_hash[:slack][:username]
        self.webhook = config_hash[:slack][:webhook]
        self.icon_url = config_hash[:slack][:icon_url]
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

# GLI_DEBUG=true bin/sport-ngin-aws-auditor audit --config_hash="{:slack_token=>{\"token\"=>\"S5msluvHPL9Y7k558yFgFvF8\"}, :slack=>{:username=>\"AWS Auditor\", :icon_url=>\"http://i.imgur.com/86x8PSg.jpg\", :channel=>\"#test-webhook-channel\", :webhook=>\"https://hooks.slack.com/services/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\"}}" -s staging


