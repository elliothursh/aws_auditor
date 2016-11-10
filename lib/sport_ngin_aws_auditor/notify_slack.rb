require 'httparty'

module SportNginAwsAuditor
  class NotifySlack
    attr_accessor :text, :channel, :webhook, :username, :icon_url, :icon_emoji, :attachments, :config

    def initialize(text, config_params)
      self.text = text
      self.attachments = []
      self.config = SportNginAwsAuditor::Config.slack.merge(eval(config_params)) if config_params
      # config_file = SportNginAwsAuditor::Config.slack || {}
      # self.config = config_params ? config_file.merge(eval(config_params)) : config_file

      if self.config
        self.channel = self.config[:channel]
        self.username = self.config[:username]
        self.webhook = self.config[:webhook]
        self.icon_url = self.config[:icon_url]
      else
        puts "To use Slack, you must provide either a separate config file or a hash of config data. See the README for more information."
      end
    end

    def perform
      if config
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
