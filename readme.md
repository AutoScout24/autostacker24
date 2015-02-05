# AutoStacker24

AutoStacker24 is a small ruby module for managing AWS CloudFormation stacks.

In comparision to the original [AWS Ruby SDK](http://docs.aws.amazon.com/AWSRubySDK/latest/frames.html)
AutoStacker 24 lets you write simple and convenient automation scripts,
especially if you have lots of parameters or dependencies between other stacks.

## Create or Update
```ruby
Stacker.create_or_update_stack(stack_name, template, parameters, parent_stack_name = nil)
```
Creates or updates the stack depending if it exists or not.
It will also wait until the stack operation is eventually finished, handling all status checks for you.

  - `template`: is either the template json data itself or the name of a file containing the template body
  - `parameters`: specify the input parameter as a simple ruby hash. It gets converted to the
    cumbersome AWS format automatically.
    The template body will be validated and optionally preprocessed.
  - `parent_stack_name`: this special feature will read the output parameters of an existing stack and
    merge them to the given parameters. Therefore the new stack can easily reference resources
    (e.g. VPC Ids or Security Groups) from a parent stack.

Example:

```ruby
params = {
  ReadThroughput:  25,
  WriteThroughput: 10,
  AmiId:           "ami-4711"
}

Stacker.create_or_update_stack('my-stack, 'service-stack.json', params)
```

For finer control Stacker offers also

  - `create_stack`
  - `update_stack`
  - `delete_stack`
  - `validate_stack`
  - `get_stack_outputs`
  - `get_stack_resources`
  - `find_stack, all_stacks, all_stack_names`

## Template Preprocessing

1. You can put javascript like comments in jour template, even if they are are illegal in pure json.
   Nevertheless, sometimes it's just handy to have the ability to quickly comment some parts out.
   AutoStacker24 will remove all comments before passing the template to AWS.

2. Referencing parameters in CloudFormation json can be quite cumbersome, especially if you build
   long strings. AutoStacker24 gives you a more convenient syntax: Inside a string, you can
   reference a parameter with the `@` symbol without the need for complex `Fn::Join` and `Ref` constructs.

  instead of  | just write
  ------------- | -------------
  `"prop": {"Ref": "myVar"}` | `"prop": "@myVar"`
  ```"prop": {"Fn::Join":["-",[{"Ref":"AWS::StackName"},{"Ref":"tableName"},"test"]]}```|```"prop": "@AWS::StackName-@tableName-test"```
  `"prop": "bla@@hullebulle.org"` | `"prop": "bla@hullebulle.org"`

By default, AutoStacker24 don't preprocess templates. If you want to use this functionality
your template must start with a comment:

```javascript
// AutoStacker24
{
  ...
}
```
`Stacker.template_body(template)` will give you the result after preprocessing if you need it for other tools.

## Using

Declare a dependency on the gem, preferably in a Gemfile:

```ruby
gem 'autostacker24'
```
Use it in your rakefile or Ruby code:

```ruby
require 'autostacker24'
```
