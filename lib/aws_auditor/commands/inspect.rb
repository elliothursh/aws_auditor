arg :aws_account
desc 'Reviews Stack Instances'
command 'inspect' do |c|
	c.switch [:e, :ec2], :desc => "Only audit EC2 instances"
	c.switch [:d, :rds], :desc => "Only audit RDS instances"
	c.switch [:c, :cache], :desc => "Only audit ElastiCache instances"
  c.action do |global_options, options, args|
    require_relative '../scripts/inspect'
    raise ArgumentError, 'You must specify an AWS account' unless args.first
    AwsAuditor::Scripts::Inspect.execute(args.first,options)
  end
end