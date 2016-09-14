require "sport_ngin_aws_auditor"

module SportNginAwsAuditor
  describe RecentlyRetiredTag do
    it 'should have an instance name as an instance_name' do
      tag = RecentlyRetiredTag.new('09/01/2000', 'Linux VPC us-east-1b t2.small')
      expect(tag.instance_name).to eq('Linux VPC us-east-1b t2.small')
    end

    it 'should have a string date as a value' do
      tag = RecentlyRetiredTag.new('09/01/2000', 'Linux VPC us-east-1b t2.small')
      expect(tag.value).to eq('09/01/2000')
    end
  end
end
