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

## How-to

### AWS Setup
Create a `.aws.yml` file in your home directory with the following structure.

```yaml
---
account1:
  access_key_id: 'ACCESS_KEY_ID'
  secret_access_key: 'SECRET_ACCESS_KEY'
account2:
  access_key_id: 'ACCESS_KEY_ID'
  secret_access_key: 'SECRET_ACCESS_KEY
```

### Google Setup (optional)
You can export audit information to a Google Spreadsheet, but you must first follow “Create a client ID and client secret” on [this page](https://developers.google.com/drive/web/auth/web-server) to get a client ID and client secret for OAuth. Then create a `.google.yml` in your home directory with the following structure.

```yaml
---
credentials:
  client_id: 'GOOGLE_CLIENT_ID'
  client_secret: 'GOOGLE_CLIENT_ID'
file:
  path: 'DESIRED_PATH_TO_FILE' #optional, creates in root directory otherwise
  name: 'NAME_OF_FILE'
```
 
## Usage

To find discrepancies between number of running instances and purchased instances, run:

    $ aws_auditor audit account1

To list information about all running instances in your account, run:

    $ aws_auditor inspect account1

To export audit information to a Google Spreadsheet, make sure you added a `.google.yml` and run:

    $ aws_auditor export -d account1
    
## Contributing

1. Fork it ( https://github.com/elliothursh/aws_auditor/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request