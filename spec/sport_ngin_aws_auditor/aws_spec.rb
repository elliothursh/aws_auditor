require "sport_ngin_aws_auditor"

module SportNginAwsAuditor
  describe AWS do
    before do
      AWS.reset
    end

    context 'shared credentials file without mfa' do
      before :each do
        mfa_devices = double('mfa_devices', mfa_devices: [])
        iam_client = double('iam_client', list_mfa_devices: mfa_devices)
        allow(Aws::IAM::Client).to receive(:new).and_return(iam_client)
        AWS.configure('staging', {})
      end

      it "should receive new Aws::SharedCredentials" do
        expect(Aws::SharedCredentials).to receive(:new).with(profile_name: 'staging').and_call_original
        AWS.auth_with_iam
      end

      it "should set credentials" do
        coffee_types = {:coffee => "cappuccino", :beans => "arabica"}
        allow(Aws::SharedCredentials).to receive(:new).and_return(coffee_types)
        AWS.auth_with_iam
        expect(AWS.credentials).to_not be_nil
      end
    end

    context 'shared credentials file with mfa' do
      it "should use MFA when user has device configured" do
        shared_credentials = double('shared_credentials', access_key_id: 'access_key_id',
                                                          secret_access_key: 'secret_access_key')
        shared_creds = double('shared_creds', credentials: shared_credentials)
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
        expect(Aws::SharedCredentials).to receive(:new).and_return(shared_creds).twice
        AWS.auth_with_iam
      end
    end

    context "using AWS server role" do
      it "should configure SDK integration and return client" do
        AWS.configure('staging', aws_roles: true)
        expect(AWS.environment).to eq('staging')
        expect(AWS.credentials).to be_nil
        expect(AWS.ec2).to_not be_nil
      end
    end

    context 'using cross account assumed roles' do
      before :each do
        cred_double = double('cred_hash', access_key_id: 'access_key_id',
                                          secret_access_key: 'secret_access_key',
                                          session_token: 'session_token')
        new_creds = double('new_creds', credentials: cred_double)
        shared_credentials = double('shared_credentials', access_key_id: 'access_key_id',
                                    secret_access_key: 'secret_access_key')
        shared_creds = double('shared_creds', credentials: shared_credentials)
        @sts = double('sts', get_session_token: new_creds)
        allow(Aws::STS::Client).to receive(:new).and_return(@sts)
        allow(Aws::AssumeRoleCredentials).to receive(:new).and_return(cred_double)
        expect(Aws::SharedCredentials).to receive(:new).and_return(shared_creds)
      end

      it "should set credentials" do
        AWS.auth_with_assumed_roles('999999999999', 'CrossAccountAuditorAccess')
        expect(AWS.credentials).to_not be_nil
      end
    end
  end
end
