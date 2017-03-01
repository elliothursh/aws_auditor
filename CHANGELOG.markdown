#### v4.1.0
* Write a message reporting when the auditor fails for any reason

  > Emma Sax: Unknown User: https://github.com/sportngin/sport_ngin_aws_auditor/pull/36

#### v4.0.2
* Define availability zone as attribute for RDS object to avoid errors

  > Emma Sax: Unknown User: https://github.com/sportngin/sport_ngin_aws_auditor/pull/35

#### v4.0.1
* Concat all of the similar values into one value right before printing

  > Emma Sax: Unknown User: https://github.com/sportngin/sport_ngin_aws_auditor/pull/27

#### v4.0.0
* Adding abilities to audit cross account

  > Emma Sax: Unknown User: https://github.com/sportngin/sport_ngin_aws_auditor/pull/31

#### v3.11.3
* Missed this bug because I did not test previous bug's fix in Slack

  > Emma Sax: Unknown User: https://github.com/sportngin/sport_ngin_aws_auditor/pull/30

#### v3.11.2
* We actually do not want to cache the counts of instances and reserved instances between multiple runs

  > Emma Sax: Unknown User: https://github.com/sportngin/sport_ngin_aws_auditor/pull/29

#### v3.11.1
* Must merge this PR in to run the audit command correctly

  > Emma Sax: Unknown User: https://github.com/sportngin/sport_ngin_aws_auditor/pull/28

#### v3.11.0
* Automatically ignore instances based on a regex string

  > Emma Sax: Unknown User: https://github.com/sportngin/sport_ngin_aws_auditor/pull/26

#### v3.10.1
* Caching should not affect RI counts between runs

  > Emma Sax: Andy Fleener, Unknown User: https://github.com/sportngin/sport_ngin_aws_auditor/pull/25

#### v3.10.0
* Handling region-based RIs

  > Emma Sax: Andy Fleener, Luke Ludwig, Tim Sandquist, Unknown User: https://github.com/sportngin/sport_ngin_aws_auditor/pull/21

#### v3.9.0
* Add the ability to pass config data in as a flag

  > Emma Sax: Andy Fleener, Unknown User: https://github.com/sportngin/sport_ngin_aws_auditor/pull/24

#### v3.8.3
* Fixing bugs with outputs and counts

  > Emma Sax: Tim Sandquist, Unknown User: https://github.com/sportngin/sport_ngin_aws_auditor/pull/23

#### v3.8.2
* Fixing bugs so that counts are accurate again

  > Emma Sax: : https://github.com/sportngin/sport_ngin_aws_auditor/pull/20

#### v3.8.1
#### v3.8.0
* Clarifying printout of audit command

  > Emma Sax: : https://github.com/sportngin/sport_ngin_aws_auditor/pull/18

#### v3.7.0
* Print retired tags into slack/terminal on audit

  > Emma Sax: Brian Bergstrom: https://github.com/sportngin/sport_ngin_aws_auditor/pull/17

#### v3.6.0
* Print reserved instances that have retired in past week

  > Emma Sax: Andy Fleener: https://github.com/sportngin/sport_ngin_aws_auditor/pull/16

#### v3.5.0
* Cleaning up slack printouts with the audit command

  > Emma Sax: Brian Bergstrom: https://github.com/sportngin/sport_ngin_aws_auditor/pull/15

#### v3.4.1
#### v3.4.0
* Add other RDS engine types

  > matl33t: Emma Sax, Brian Bergstrom: https://github.com/sportngin/sport_ngin_aws_auditor/pull/11

#### v3.3.1
* Fixing bug where Slack will print discrepancies if there are *only* tagged instances

  > Emma Sax: : https://github.com/sportngin/sport_ngin_aws_auditor/pull/13

#### v3.3.0
* Slack should print instances that have tags

  > Emma Sax: Andy Fleener: https://github.com/sportngin/sport_ngin_aws_auditor/pull/12

#### v3.2.0
* Proper recognition of windows/linux/vpc instances

  > Emma Sax: Andy Fleener: https://github.com/sportngin/sport_ngin_aws_auditor/pull/8

#### v3.1.2
#### v3.1.0
* Authentication with AWS roles instead of credentials file

  > Emma Sax: Brian Bergstrom: https://github.com/sportngin/sport_ngin_aws_auditor/pull/7

#### v3.0.2
#### v3.0.1
#### v3.0.0
* Rename gem directories and modules

  > Emma Sax: Brian Bergstrom: https://github.com/sportngin/sport_ngin_aws_auditor/pull/6

#### v2.1.0
* Adding option to print audit results to Slack channel

  > Emma Sax, Matt Krieger: Brian Bergstrom: https://github.com/sportngin/aws_auditor/pull/4

* Adding option to print audit results to Slack channel

  > Emma Sax, Matt Krieger: Brian Bergstrom: https://github.com/sportngin/aws_auditor/pull/4

#### v2.0.0
* Adding enhancements for taking no-reserved-instance tag into consideration during audit

  > Emma Sax: Brian Bergstrom: https://github.com/sportngin/aws_auditor/pull/2

#### v1.0.0
* Upgrading aws-sdk version from v1 to v2

  > Emma Sax: Brian Bergstrom: https://github.com/sportngin/aws_auditor/pull/3

* First tests, Travis CI, MFA support, and fog file compatibility

  > Brian Bergstrom: Emma Sax: https://github.com/sportngin/aws_auditor/pull/1
