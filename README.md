# AwsAuditor

Audits your AWS accounts to find discrepancies between the number of running instances and purchased reserved instances.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'aws_auditor'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install aws_auditor

## Usage

Create a `.aws.yml` file in the root directory, with the following structure.

```yaml
---
account1:
  access_key_id: 'ACCESS_KEY_ID'
  secret_access_key: 'SECRET_ACCESS_KEY
account2:
  access_key_id: 'ACCESS_KEY_ID'
  secret_access_key: 'SECRET_ACCESS_KEY
```

To find discrepancies between number of running instances and purchased instances, run:

    $ aws_auditor audit account1

To list instances for all stacks in your account, run:

    $ aws_auditor stack-audit account1
    
## Contributing

1. Fork it ( https://github.com/[my-github-username]/aws_auditor/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request