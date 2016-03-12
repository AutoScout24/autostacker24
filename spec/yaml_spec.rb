require 'spec_helper'
require 'yaml'


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
    Data: |
      some very long
      text splitted over
      lines
    UserData: bla
    EOL
  end

  subject(:parsed_template) do
    JSON.parse(Stacker.template_body(template))
  end

  it 'can read strings' do
    expect(parsed_template['Description']).to eq('My Stack')
  end

  it 'can read arrays' do
    expect(parsed_template['Parameters']['Environment']['AllowedValues']).to eq(%w(Staging Production))
  end

  it 'can read integers' do
    expect(parsed_template['Parameters']['DBName']['Priority']).to eq(5)
  end

  it 'can read long text' do
    expect(parsed_template['Data']).to eq("some very long\ntext splitted over\nlines\n")
  end
end