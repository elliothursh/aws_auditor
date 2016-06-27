require "aws_auditor"

module AwsAuditor
  describe AWSSDK do
    context 'without mfa' do
      before :each do
        device = double('mfa_device', serial_number: nil)
        mfa_devices = double('mfa_devices', mfa_devices: [device])
        iam_client = double('iam_client', list_mfa_devices: mfa_devices)
        allow(Aws::IAM::Client).to receive(:new).and_return(iam_client)
      end

      it "should receive new Aws::SharedCredentials" do
        expect(Aws::SharedCredentials).to receive(:new).with(profile_name: 'staging')
        AWSSDK::authenticate('staging')
      end

      it "should update configs" do
        coffee_types = {:coffee => "cappuccino", :beans => "arabica"}
        allow(Aws::SharedCredentials).to receive(:new).and_return(coffee_types)
        expect(Aws.config).to receive(:update).with({region: 'us-east-1', credentials: coffee_types})
        AWSSDK::authenticate('staging')
      end
    end

    context 'with mfa' do
      it "should use MFA if it should" do
        cred_double = double('cred_hash', access_key_id: 'access_key_id',
                                          secret_access_key: 'secret_access_key',
                                          session_token: 'session_token')
        new_creds = double('new_creds', credentials: cred_double)
        sts = double('sts', get_session_token: new_creds)
        allow(Output).to receive(:ask).and_return(123456)
        allow(Aws::STS::Client).to receive(:new).and_return(sts)
        device = double('mfa_device', serial_number: "arn:aws:iam::1234567890:mfa/test.user")
        mfa_devices = double('mfa_devices', mfa_devices: [device])
        iam_client = double('iam_client', list_mfa_devices: mfa_devices)
        allow(Aws::IAM::Client).to receive(:new).and_return(iam_client)

        expect(Aws::Credentials).to receive(:new).and_return(cred_double).at_least(:once)
        AWSSDK::authenticate('staging')
      end
    end
  end
end
