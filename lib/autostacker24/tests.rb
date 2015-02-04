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
     "nested": {"one": "nested", "two": "@AWS::StackName"}
   }
   EOF

   puts AutoStacker24::Preprocessor.tokenize('bla @@@var2 @bla2 xyz').inspect
   puts Stacker.template_body(template)
end

if $0 ==__FILE__ # placeholder for interactive testing
  $stderr.sync=true
  $stdout.sync=true

  #OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE # Windows Hack

  remove_comments
  replace_variables

end
