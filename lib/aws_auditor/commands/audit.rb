desc 'Reviews Reserved Instances'
command 'audit' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/audit'
    AwsAuditor::Scripts::Audit.execute args.first
  end
end