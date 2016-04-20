require 'spec_helper'
require 'json'

RSpec.describe 'Stacker Template Processing' do
  let(:template) do
    <<-EOL
    // AutoStacker24
    {
      "bla": "bla", //comment
      "fasel": "//no comment",
      "blub": // still a "comment"
      "some string", // comment
      "single": "@var1",
      "embedded": "bla @var2 @bla2",
      "array": ["@var2", "@var3"],
      "escape": "bla@@bla.com",
      "nested": {"one": "nested", "two": "@AWS::StackName123-bla"},
      "content" : { "Fn::Join" : ["", ["[general]\\n", "state_file = /var/lib/awslogs/agent-state\\n", "\\n"]]},
      "single_colon": "@AWS::Stack:something@Other",
      "file_include": {
        "UserData": "@file://./spec/example_script.sh",
        "NonUserData": "@file://./spec/example_script.sh"
      },
      "file_curly_include": {
        "UserData": "@{file://./spec/example_script.sh}",
        "NonUserData": "@{file://./spec/example_script.sh}"
      },
      "auto_encode": {
        "UserData": "auto encode"
      },
      "already_encoded": {
        "UserData": {"Fn::Base64": "#!/bin/bash"}
      },
      "find_in_map": "@{EnvMap[@Env, Key]}",
      "find_in_map_convention": "@{Env[Key]}"
    }
    EOL
  end

  subject(:processed) { JSON.parse(Stacker.template_body(template)) }

  it 'generates Fn:FindInMap elements' do
    expected = { 'Fn::FindInMap' => ['EnvMap', { 'Ref' => 'Env' }, 'Key'] }
    expect(processed['find_in_map']).to eq(expected)
  end

  it 'generates Fn:FindInMap elements by convention' do
    expected = { 'Fn::FindInMap' => ['EnvMap', { 'Ref' => 'Env' }, 'Key'] }
    expect(processed['find_in_map_convention']).to eq(expected)
  end

  it 'removes any comments into valid json' do
    begin
      expect(processed['bla']).to eq('bla')
      expect(processed['fasel']).to eq('//no comment')
    rescue JSON::ParserError => e
      raise "unparsable JSON output: #{e.message}"
    end
  end

  it 'substitutes a single variable' do
    expect(processed['single']).to eq('Ref' => 'var1')
  end

  it 'replaces an embedded variable' do
    expected_join_hash = { 'Fn::Join' => ['', ['bla ', { 'Ref' => 'var2' }, ' ', { 'Ref' => 'bla2' }]] }
    expect(processed['embedded']).to eq(expected_join_hash)
  end

  it 'replaces variables in an array' do
    expect(processed['array']).to eq([{ 'Ref' => 'var2' }, { 'Ref' => 'var3' }])
  end

  it 'does not replace an escaped @' do
    expect(processed['escape']).to eq('bla@bla.com')
  end

  it 'preserves content' do
    expected_join_hash = { 'Fn::Join' => ['', ["[general]\n", "state_file = /var/lib/awslogs/agent-state\n", "\n"]] }
    expect(processed['content']).to eq(expected_join_hash)
  end

  it 'includes only double semicolon in variable name' do
    expected_join_hash = { 'Fn::Join' => ['', [{ 'Ref' => 'AWS::Stack' }, ':something', { 'Ref' => 'Other' }]] }
    expect(processed['single_colon']).to eq(expected_join_hash)
  end

  it 'substitutes @file:// with file content' do
    content = {'Fn::Join' =>['', ["#!/bin/bash\n\necho \"", {'Ref' => 'Version'}, "\"\n"]]}
    expect(processed['file_include']['NonUserData']).to eq(content)
  end

  it 'substitutes @file:// in UserData with file content and encodes it in base64' do
    user_data = {'Fn::Join' =>['', ["#!/bin/bash\n\necho \"", {'Ref' => 'Version'}, "\"\n"]]}
    expect(processed['file_include']['UserData']).to eq('Fn::Base64' => user_data)
  end

  it 'substitutes @{file://...} with file content' do
    content = {'Fn::Join' =>['', ["#!/bin/bash\n\necho \"", {'Ref' => 'Version'}, "\"\n"]]}
    expect(processed['file_curly_include']['NonUserData']).to eq(content)
  end

  it 'substitutes @{file://...} in UserData with file content and encodes it in base64' do
    user_data = {'Fn::Join' =>['', ["#!/bin/bash\n\necho \"", {'Ref' => 'Version'}, "\"\n"]]}
    expect(processed['file_curly_include']['UserData']).to eq('Fn::Base64' => user_data)
  end

  it 'wraps userData in a Base64 encoded block' do
    expect(processed['auto_encode']['UserData']).to eq('Fn::Base64' => 'auto encode')
  end

  it 'does not double wrap encoded blocks' do
    expect(processed['already_encoded']['UserData']).to eq('Fn::Base64' => '#!/bin/bash')
  end
end
