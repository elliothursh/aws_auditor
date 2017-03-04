arg :aws_account
desc 'Reviews Stack Instances'
command 'inspect' do |c|
  c.switch [:e, :ec2], :desc => "Only inspect EC2 instances"
  c.switch [:d, :rds], :desc => "Only inspect RDS instances"
  c.switch [:c, :cache], :desc => "Only inspect ElastiCache instances"
  c.action do |global_options, options, args|
    require 'sport_ngin_aws_auditor/scripts/inspect'
    raise ArgumentError, 'You must specify an AWS account' unless args.first
    SportNginAwsAuditor::Scripts::Inspect.execute(args.first,options, global_options)
  end
end
