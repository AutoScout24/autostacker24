require 'openssl'
require_relative 'stacker.rb'

def template_body
  template = <<-EOL
    bla bla //comment
    bla "//no comment"
    bla // still a "comment"
    bla "some string" // comment
  EOL

  puts Stacker.template_body(template)
end

if $0 ==__FILE__ # placeholder for interactive testing

  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE # Windows Hack

  template_body

end
