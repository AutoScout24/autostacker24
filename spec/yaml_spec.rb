require 'spec_helper'
require 'yaml'


RSpec.describe 'Keep YAML' do

  let(:template) do
    <<-EOL
    AWSTemplateFormatVersion: "2010-09-09"
    Description: My Stack
    Parameters:
      Environment: # Some Comments
        Type: "String"
        AllowedValues:
          - Staging
          - Production
      DBName:
        Type: String
        Default: my-db
        Priority: 5
    Text: |
      some very long
      text splitted over
      lines
    StackName: !Ref AWS::StackName
    UserData: |
      #!/bin/bash
      echo "@Environment"
      exit 42
    EOL
  end

  subject(:parsed) do
    YAML.load(Stacker.template_body(template))
  end

  it 'does not manipulate the template' do
    expect(parsed['UserData']).to eq("#!/bin/bash\necho \"@Environment\"\nexit 42\n")
  end

end


RSpec.describe 'YAML to JSON' do

  let(:template) do
    <<-EOL
    # AutoStacker24 enabled CloudFormation template
    AWSTemplateFormatVersion: "2010-09-09"
    Description: My Stack
    Parameters:
      Environment: # Some Comments
        Type: "String"
        AllowedValues:
          - Staging
          - Production
      DBName:
        Type: String
        Default: my-db
        Priority: 5
    Text: |
      some very long
      text splitted over
      lines
    StackName: "@AWS::StackName"
    UserData: |
      #!/bin/bash
      echo "@Environment"
      exit 42
    EOL
  end

  subject(:parsed) do
    JSON.parse(Stacker.template_body(template))
  end

  it 'reads strings' do
    expect(parsed['Description']).to eq('My Stack')
  end

  it 'reads arrays' do
    expect(parsed['Parameters']['Environment']['AllowedValues']).to eq(%w(Staging Production))
  end

  it 'reads integers' do
    expect(parsed['Parameters']['DBName']['Priority']).to eq(5)
  end

  it 'reads long strings' do
    expect(parsed['Text']).to eq("some very long\ntext splitted over\nlines\n")
  end

  it 'expands parameters' do
    expect(parsed['StackName']).to eq({'Ref' => 'AWS::StackName'})
  end

  it 'expands parameters inside long user data' do
    user_data = {'Fn::Join' => ['', ["#!/bin/bash\necho \"", {'Ref' => 'Environment'}, "\"\nexit 42\n"]]}
    expect(parsed['UserData']).to eq({'Fn::Base64' => user_data})
  end
end