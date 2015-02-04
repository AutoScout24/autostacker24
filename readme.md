# AutoStacker24

AutoStacker24 is a small ruby library for managing AWS CloudFormation stacks.

## Additions

AutoStacker24 can preprocess your CloudFormation template if it starts with the following comment.

    // AutoStacker24

1. You can put javascript like comments in jour template.
   As comments are illegal in pure json, they must be removed before transferring the template
   to CloudFormation. Nevertheless, sometimes it's just handy to have the ability to comment some parts out.

2. Using variables in CloudFormation json can be quite cumbersome, especially if you need them in
   long strings, e.g. user data for ec2 instances.
   - "@myVar" becomes {"Ref": "myVar"}
   - "first @varOne second @varTwo" becomes {"Fn::Join":["",["first ", {"Ref": "varOne"}, " second ", {"Ref":"varTwo"}]]}
   - "bla@@hullebulle.org" becomes "bla@hullebulle.org"

## Using

Declare a dependency on the gem, preferably in a Gemfile:

    gem 'autostacker24'

Use it in your rakefile or Ruby code:

    require 'autostacker24'

