require "sport_ngin_aws_auditor"

module SportNginAwsAuditor
  describe RecentlyRetiredTag do
    it 'should have an instance name as an instance_type' do
      tag = RecentlyRetiredTag.new('09/01/2000', 'Linux VPC us-east-1b t2.small', 'Tag name', 'This is an example')
      expect(tag.instance_type).to eq('Linux VPC us-east-1b t2.small')
    end

    it 'should have a name as the instance_name' do
      tag = RecentlyRetiredTag.new('09/01/2000', 'Linux VPC us-east-1b t2.small', 'Tag name', 'This is an example')
      expect(tag.instance_name).to eq('Tag name')
    end

    it 'should have a string description as the reason' do
      tag = RecentlyRetiredTag.new('09/01/2000', 'Linux VPC us-east-1b t2.small', 'Tag name', 'This is an example')
      expect(tag.reason).to eq('This is an example')
    end

    it 'should have nil as the reason' do
      tag = RecentlyRetiredTag.new('09/01/2000', 'Linux VPC us-east-1b t2.small', 'Tag name')
      expect(tag.reason).to eq(nil)
    end

    it 'should have a string date as a value' do
      tag = RecentlyRetiredTag.new('09/01/2000', 'Linux VPC us-east-1b t2.small', 'Tag name')
      expect(tag.value).to eq('09/01/2000')
    end
  end
end
