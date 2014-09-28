desc 'Reviews Reserved Instances'
command 'audit' do |c|
	c.switch :ec2, :desc => "Only audit EC2 instances"
	c.switch :rds, :desc => "Only audit RDS instances"
	c.switch :cache, :desc => "Only audit ElastiCache instances"
  c.action do |global_options, options, args|
    require_relative '../scripts/audit'
    raise ArgumentError, 'You must specify an AWS account' unless args.first
    AwsAuditor::Scripts::Audit.execute(args.first,options)
  end
end