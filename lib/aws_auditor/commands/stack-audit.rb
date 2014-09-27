arg :environment
desc 'Reviews Stack Instances'
command 'stack-audit' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/stack-audit'
    AwsAuditor::Scripts::StackAudit.execute args.first
  end
end