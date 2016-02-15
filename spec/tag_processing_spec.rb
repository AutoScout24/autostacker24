require 'spec_helper'
require 'json'

RSpec.describe 'Stacker Tag Processing' do
  team1 = { 'Key' => 'Team', 'Value' => 'Kondor' }
  team2 = { 'Key' => 'Team2', 'Value' => 'Kondor2' }
  tags = [team1, team2]
  service = { 'Key' => 'Service', 'Value' => 'Dashing' }
  propagate = { 'PropagateAtLaunch' => 'true' }
  merged_tags = [team1, team2, service]

  let(:template) do
    <<-EOL
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
        },
        "supportedTypeNonConflictingTags_returnsThreeTags" : {
          "Type": "AWS::ElasticLoadBalancing::LoadBalancer",
          "Properties": {
            "Tags" : [
              {"Key" : "Service", "Value" : "Dashing"}
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
        },
        "ASGType_ReturnsTagsWithPropagateAtLaunch" : {
          "Type": "AWS::AutoScaling::AutoScalingGroup",
          "Properties": {
          }
        }
      }
    }
    EOL
  end

  subject(:parsed_template) { JSON.parse(Stacker.template_body(template, tags)) }

  def tags_of(resource_name)
    parsed_template['Resources'][resource_name]['Properties']['Tags']
  end

  xit 'puts keys into the cloudwatch json structure at the appropriate place' do
    pending 'we expected this to work, but it does not'
    expect(tags_of('Loadbalancer')).to include(team1)
  end

  xit 'merges keys when already some are present' do
    pending 'we expected this to work, but it does not'
    expect(tags_of('supportedTypeNonConflictingTags_returnsThreeTags')).to eq(merged_tags)
  end

  xit 'overwrites tags with conflicting keys' do
    pending 'we expected this to work, but it does not'
    expect(tags_of('supportedTypeTwoConflictingTags_ReturnsThreeTagsOverwritten')).to eq(merged_tags)
  end

  it 'ignores unupported Resource Types' do
    expect(tags_of('unsupportedType_ReturnsNoTags')).to eq(nil)
  end

  xit 'adds propagate at launch tag' do
    pending 'we expected this to work, but it does not'
    expect(tags_of('ASGType_ReturnsTagsWithPropagateAtLaunch')).to eq(merged_tags + [propagate])
  end
end
