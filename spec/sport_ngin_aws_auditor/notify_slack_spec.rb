require "sport_ngin_aws_auditor"

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
      notifier = double('notifier', ping: true)
      allow(Slack::Notifier).to receive(:new).and_return(notifier)
      expect(notifier).to receive(:ping).and_return(true)
      message = NotifySlack.new("Test message")
      message.perform
    end

     it 'should define certain values' do
      message = NotifySlack.new("Test message")
      expect(message.text).to eq("Test message")
      expect(message.channel).to eq("#random-test-channel")
      expect(message.username).to eq("Random User")
      expect(message.webhook).to eq("https://hooks.slack.com/services/totallyrandom/fakewebhookurl")
      expect(message.icon_url).to eq("http://random-picture.jpg")
    end
  end
end
