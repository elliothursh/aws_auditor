require "sport_ngin_aws_auditor"
require 'json'

module SportNginAwsAuditor
  describe NotifySlack do
    before :each do
      config_file = {"slack" => {"channel" => "#random-test-channel",
                                 "username" => "Random User",
                                 "webhook" => "https://hooks.slack.com/services/totallyrandom/fakewebhookurl",
                                 "icon_url" => "http://random-picture.jpg"}
                    }
      expect(YAML).to receive(:load_file).and_return(config_file)
      expect(File).to receive(:exist?).and_return(true)
      SportNginAwsAuditor::Config.load("dummy/path")
    end

    it 'should ping Slack Notifier' do
      notifier = double('notifier')
      expect(HTTParty).to receive(:post)
      message = NotifySlack.new("Test message", nil)
      message.perform
    end

     it 'should define certain values' do
      message = NotifySlack.new("Test message", nil)
      expect(message.text).to eq("Test message")
      expect(message.channel).to eq("#random-test-channel")
      expect(message.username).to eq("Random User")
      expect(message.webhook).to eq("https://hooks.slack.com/services/totallyrandom/fakewebhookurl")
      expect(message.icon_url).to eq("http://random-picture.jpg")
    end

    it 'should ping Slack Notifier even when passing in config as a hash' do
      notifier = double('notifier')
      config_hash = {:username=>"AWS Auditor",
                     :icon_url=>"http://i.imgur.com/86x8PSg.jpg",
                     :channel=>"#test-webhook-channel",
                     :webhook=>"https://hooks.slack.com/services/thisisafake"
                    }.to_json
      expect(HTTParty).to receive(:post)
      message = NotifySlack.new("Test message", config_hash)
      message.perform
    end
  end
end
