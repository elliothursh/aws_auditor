require 'httparty'

module SportNginAwsAuditor
  class NotifySlack
    attr_accessor :text, :channel, :webhook, :username, :icon_url, :icon_emoji, :attachments

    def initialize(text, config_hash)
      self.text = text
      self.attachments = []

      if SportNginAwsAuditor::Config.slack
        self.channel = SportNginAwsAuditor::Config.slack[:channel]
        self.username = SportNginAwsAuditor::Config.slack[:username]
        self.webhook = SportNginAwsAuditor::Config.slack[:webhook]
        self.icon_url = SportNginAwsAuditor::Config.slack[:icon_url]
      elsif config_hash
        hs = eval(config_hash)
        self.channel = hs[:slack][:channel]
        self.username = hs[:slack][:username]
        self.webhook = hs[:slack][:webhook]
        self.icon_url = hs[:slack][:icon_url]
      else
        puts "To use Slack, you must provide either a separate config file or a hash of config data. See the README for more information."
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

# GLI_DEBUG=true bin/sport-ngin-aws-auditor audit --config_hash='{:slack_token =>["S5msluvHPL9Y7k558yFgFvF8"],:slack=>{:username=>"AWS Auditor",:icon_url=>"http://i.imgur.com/86x8PSg.jpg",:channel=>"#ops-firehose",:webhook=>"https://hooks.slack.com/services/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"}}' -s staging
