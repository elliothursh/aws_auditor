arg :aws_account
desc 'Export an Audit to Google SpreadSheets'
command 'export' do |c|
  c.switch [:c, :csv], :desc => "Exports to CSV"
  c.switch [:d, :drive], :desc => "Exports to Google Drive"
  c.action do |global_options, options, args|
    require_relative '../scripts/export'
    raise ArgumentError, 'You must specify an AWS account' unless args.first
    SportNginAwsAuditor::Scripts::Export.execute(args.first, options, global_options)
  end
end
