arg :aws_account
desc 'Export an Audit to Google SpreadSheets'
command 'export' do |c|
  c.action do |global_options, options, args|
    require_relative '../scripts/export'
    raise ArgumentError, 'You must specify an AWS account' unless args.first
    AwsAuditor::Scripts::Export.execute(args.first, options)
  end
end