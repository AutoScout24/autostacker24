require 'openssl'
require_relative 'stacker.rb'

def remove_comments
  template = <<-EOL
  // AutoStacker24
  {
    "bla": "bla", //comment
    "fasel": "//no comment",
    "blub": // still a "comment"
    "some string" // comment
  }
  EOL

  puts Stacker.template_body(template)
  puts Stacker.template_body("//AutoStacker\n{\"bla\":\"@blub\"}")
end

def replace_variables
  template = <<-EOF
   // AutoStacker24
   {
     "bla": 5,
     "single": "@var1",
     "embedded": "bla @var2 @bla2",
     "array": ["@var2", "@var3"],
     "escape": "bla@@bla.com",
     "nested": {"one": "nested", "two": "@AWS::StackName123-bla"},
     "content" : { "Fn::Join" : ["", ["[general]\\n", "state_file = /var/lib/awslogs/agent-state\\n", "\\n"]]},
     "single_colon": "@AWS::Stack:something@Other"
   }
   EOF

   puts AutoStacker24::Preprocessor.tokenize('content').inspect
   puts AutoStacker24::Preprocessor.tokenize('bla @@@var2 @bla2 xyz').inspect
   puts Stacker.template_body(template)
end


def merge_tags
  template = <<-EOF
   // AutoStacker24
   {
     "Resources" : {
       "Loadbalancer" : {
         "Type": "AWS::ElasticLoadBalancing::LoadBalancer",
         "SomethingElse": {
           "x": "y"
         },
         "Properties": {
           "Tags" : [
             {"Key" : "Environment", "Value" : "@AWS::StackName","PropagateAtLaunch": "true" }
           ]
         }
       }
     }
   }
   EOF

   puts Stacker.template_body(template, [{"Key": "MyKey", "Value": "MyValue"}])
   puts Stacker.template_body(template, [{"Key"=> "MyKey", "Value" => "MyValue"}])
end

def add_tags
  template = <<-EOF
   // AutoStacker24
   {
     "Resources" : {
       "supportedTypeNoTags_returnsTwoTags" : {
         "Type": "AWS::ElasticLoadBalancing::LoadBalancer",
         "Properties": {
         }
       },
       "supportedTypeNonConflictingTags_returnsThreeTags" : {
         "Type": "AWS::ElasticLoadBalancing::LoadBalancer",
         "Properties": {
           "Tags" : [
             {"Key" : "UniqueKey", "Value" : "SomeValue"}
           ]
         }
       },
       "supportedTypeTwoConflictingTags_ReturnsThreeTagsOverwritten" : {
         "Type": "AWS::ElasticLoadBalancing::LoadBalancer",
         "Properties": {
           "Tags" : [
             {"Key" : "Team", "Value" : "Old"},
             {"Key" : "Service", "Value" : "Dashing"}
           ]
         }
       },
       "unsupportedType_ReturnsNoTags" : {
         "Type": "UnsupportedType",
         "Properties": {
         }
       }
     }
   }
   EOF

   tags = [{"Key" => "Team", "Value" => "Kondor"}, {"Key" => "Team2", "Value" => "Kondor2"}]
  #  puts AutoStacker24::Preprocessor.tokenize('content').inspect
  #  puts AutoStacker24::Preprocessor.tokenize('bla @@@var2 @bla2 xyz').inspect
   puts Stacker.template_body(template, tags)
end

if $0 ==__FILE__ # placeholder for interactive testing
  $stderr.sync=true
  $stdout.sync=true

  #OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE # Windows Hack

  #remove_comments
  #replace_variables
  merge_tags
  #add_tags

end
