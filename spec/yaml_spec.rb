require 'spec_helper'
require 'yaml'


RSpec.describe "Don't preprocess if YAML has no starting comment" do

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

  subject(:emitted) do
    Stacker.template_body(template)
  end

  it 'does not manipulate the template' do
    expect(emitted).to eq(template)
  end

end

RSpec.describe "CloudFormation YAML short intrinsic function tag" do

  let(:template) do
    <<-EOL
    # AutoStacker24 enabled CloudFormation template
    Parameters:
      Environment: # Some Comments
        Type: String
        Default: Staging
    StringInterpolation: "@Environment"
    Base64: !Base64 "valueToEncode"
    FindInMap: !FindInMap [ MapName, TopLevelKey, SecondLevelKey ]
    GetAZs: !GetAZs eu-west-1
    GetAtt: !GetAtt resource.attributeName
    ImportValue: !ImportValue sharedValueToImport
    Join: !Join [ " ", [ one, two, three ] ]
    Select: !Select [ "1", [ "apples", "grapes", "oranges" ] ]
    Sub: !Sub
      - String
      - { Var1Name: Var1Value, Var2Name: Var2Value }
    Ref: !Ref AWS::StackName
    EOL
  end

  subject(:processed) do
    JSON(Stacker.template_body(template))
  end

  it 'still interpolates autostacker strings' do
    expect(processed['StringInterpolation']).to eq('Ref' => 'Environment')
  end

  it '!Base64' do
    expect(processed['Base64']).to eq('Fn::Base64' => 'valueToEncode' )
  end

  it '!FindInMap' do
    expect(processed['FindInMap']).to eq('Fn::FindInMap' => ['MapName', 'TopLevelKey', 'SecondLevelKey'])
  end

  it '!GetAZs' do
    expect(processed['GetAZs']).to eq('Fn::GetAZs' => 'eu-west-1' )
  end

  it '!GetAtt resource.attributeName' do
    expect(processed['GetAtt']).to eq('Fn::GetAtt' => ['resource', 'attributeName'])
  end

  it '!ImportValue' do
    expect(processed['ImportValue']).to eq('Fn::ImportValue' => 'sharedValueToImport')
  end

  it '!Join' do
    expect(processed['Join']).to eq('Fn::Join' => [" ", ['one', 'two', 'three']])
  end

  it '!Select' do
    expect(processed['Select']).to eq('Fn::Select' =>  ['1', ['apples', 'grapes', 'oranges']])
  end

  it '!Sub' do
    expect(processed['Sub']).to eq('Fn::Sub' => ['String', { 'Var1Name' => 'Var1Value', 'Var2Name' => 'Var2Value' }])
  end

  it '!Ref' do
    expect(processed['Ref']).to eq('Ref' => 'AWS::StackName')
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