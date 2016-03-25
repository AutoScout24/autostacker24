# AutoStacker24

AutoStacker24 is a small ruby gem for managing AWS CloudFormation stacks.
It is a thin wrapper around the
[AWS Ruby SDK](http://docs.aws.amazon.com/AWSRubySDK/latest/frames.html).
It lets you write simple and convenient automation scripts,
especially if you have lots of parameters or dependencies between stacks.
You can use it directly from Ruby code or from the command line.
It enhances CloudFormation templates by parameter expansion in strings and
it is even possible to write templates in [YAML](examples/yaml-stack.md) which is much friendlier
to humans than JSON. You can use `$ autostacker24 convert` to convert existing templates to YAML.

## Status
[![Build Status](https://travis-ci.org/AutoScout24/autostacker24.svg)](https://travis-ci.org/AutoScout24/autostacker24)

## Create or Update
```ruby
Stacker.create_or_update_stack(stack_name, template, parameters, parent_stack_name = nil, tags = nil)
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
  - `tags`: Key-value pairs to associate with this stack. As CloudFormation [does not support updating tags](http://docs.aws.amazon.com/cli/latest/reference/cloudformation/update-stack.html) AutoStacker24 is injecting the tags to all  `Resources` elements which support it.

Example:

```ruby
params = {
  ReadThroughput:  25,
  WriteThroughput: 10,
  AmiId:           "ami-4711"
}

tags = [
  { "Key": "Team", "Value": "Kondor"}
]

Stacker.create_or_update_stack('my-stack', 'service-stack.json', params, tags)
```

For finer control Stacker offers also

  - `create_stack`
  - `update_stack`
  - `delete_stack`
  - `validate_template`
  - `get_stack_outputs`
  - `get_stack_resources`
  - `find_stack, all_stacks, all_stack_names`

## Template Preprocessing

1. You can put javascript like comments in your template, even if they are are illegal in pure JSON. AutoStacker24 will remove all comments before passing the template to AWS.

2. You can use YAML for writing your templates. [YAML](http://yaml.org/spec/1.2/spec.html) is a data serialization format that is structural identical with JSON but optimized for humans.
It has support for comments and long embedded string documents which makes it is especially useful for embedded UserData.
[Example](examples/yaml-stack.md)

3. Referencing parameters and building strings is quite cumbersome in CloudFormation. AutoStacker24 gives you a more convenient syntax: Inside a string, you can reference one or more parameters with the `@` symbol without the need for complex `Fn::Join` and `Ref` constructs.

4. For the "UserData" property you can pass a simple string that gets  auto encoded to base64. This is especially useful for templates written in yaml. You can reference a file `@file://./myscript.sh` that will be read into a simple string.

5. Instead of using Fn::FindInMap you can do something like `@EnvironmentMap[@Environment, Key]`

### Examples

  instead of | just write
  ------------- | -------------
  `"prop": {"Ref": "myVar"}` | `"prop": "@myVar"`
  `"prop": {"Fn::Join":["-",[`<br/>`{"Ref":"AWS::StackName"},{"Ref":"tableName"},"test"`<br/>`]]}`|`"prop": "@AWS::StackName-@tableName-test"`
  `"prop": "bla@hullebulle.org"` | `"prop": "bla@@hullebulle.org"`
  `"UserData": {"Fn:Base64": ... }` | `"UserData": "@file://./myscript.sh"`
  `"content": {"Fn::Join":["\n", [...]]` | `"content" : "@file://./myfile.txt"`
  `"prop": {"Fn::FindInMap": ["RegionMap", { "Ref" : "AWS::Region" }, "32"]` | `"@RegionMap[@Region, 32]"` or `"@Region[32]`

By default, AutoStacker24 don't preprocess templates. If you want to use this functionality your must start your template with a comment:

```javascript
// AutoStacker24 JSON
{
  "AWSTemplateFormatVersion": "2010-09-09"
  ...
}
```
```yaml
# AutoStacker24 YAML
AWSTemplateFormatVersion: "2010-09-09"
Description: My Stack
...
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

### CLI

You can also use AutoStacker24 in your command line.

To convert a valid template from JSON to YAML

```
$ autostacker24 convert --template /path/to/template.json
```

To convert a valid template from YAML to JSON

```
$ autostacker24 convert --template /path/to/template.json --to-json
```

To Validate a template:

```
$ autostacker24 validate --template /path/to/template.json
```

To see the outcome after AutoStacker24 preprocessed your template;

```
$ autostacker24 show --template /path/to/template.json
```
