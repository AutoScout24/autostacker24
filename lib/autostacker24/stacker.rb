require 'aws-sdk-core'
require 'json'

module Stacker

  attr_reader :region, :credentials

  # use ENV['AWS_ACCESS_KEY_ID'] and ENV['AWS_SECRET_ACCESS_KEY'] if you don't want to set credentials by code
  def credentials=(credentials)
    unless credentials == @credentials
      @lazy_cloud_formation = nil
      @credentials = credentials
    end
  end

  def region=(region) # use ENV['AWS_REGION'] or ENV['AWS_DEFAULT_REGION']
    @region = region unless region == @region
  end

  def create_or_update_stack(stack_name, template, parameters, parent_stack_name = nil)
    if find_stack(stack_name).nil?
      create_stack(stack_name, template, parameters, parent_stack_name)
    else
      update_stack(stack_name, template, parameters, parent_stack_name)
    end
  end

  def create_stack(stack_name, template, parameters, parent_stack_name = nil)
    merge_output_parameters(parent_stack_name, template, parameters) if parent_stack_name
    cloud_formation.create_stack(stack_name:    stack_name,
                                 template_body: template_body(template),
                                 on_failure:    'DELETE',
                                 parameters:    transform_parameters(parameters),
                                 capabilities:  ['CAPABILITY_IAM'])
    wait_for_stack(stack_name, :create)
  end

  def update_stack(stack_name, template, parameters, parent_stack_name = nil)
    merge_output_parameters(parent_stack_name, template, parameters) if parent_stack_name
    begin
      cloud_formation.update_stack(stack_name:    stack_name,
                                   template_body: template_body(template),
                                   parameters:    transform_parameters(parameters),
                                   capabilities:  ['CAPABILITY_IAM'])
    rescue Aws::CloudFormation::Errors::ValidationError => error
      raise error unless error.message =~ /No updates are to be performed/i # may be flaky, do more research in API
      find_stack(stack_name)
    else
      wait_for_stack(stack_name, :update)
    end
  end

  def merge_output_parameters(stack_name, template, parameters)
    expected_parameters = JSON(template_body(template))['Parameters']
    get_stack_outputs(stack_name).each do |k, v|
      parameters[k.to_sym] = v if expected_parameters.has_key?(k.to_s)
    end
    parameters
  end

  def delete_stack(stack_name)
    cloud_formation.delete_stack(stack_name: stack_name)
    wait_for_stack(stack_name, :delete)
  end

  def wait_for_stack(stack_name, operation, timeout_in_minutes = 15)
    stop_time = Time.now + timeout_in_minutes * 60
    finished = /(CREATE_COMPLETE|UPDATE_COMPLETE|DELETE_COMPLETE|ROLLBACK_COMPLETE|ROLLBACK_FAILED|CREATE_FAILED|DELETE_FAILED)$/
    while Time.now < stop_time
      stack = find_stack(stack_name)
      status = stack ? stack.stack_status : 'DELETE_COMPLETE'
      expected_status = case operation
                          when :create then /CREATE_COMPLETE$/
                          when :update then /UPDATE_COMPLETE$/
                          when :delete then /DELETE_COMPLETE$/
                        end
      return true if status =~ expected_status
      fail "#{stack_name} failed, current status #{status}" if status =~ finished
      puts "waiting for #{stack_name}, current status #{status}"
      sleep(7)
    end
    fail "waiting for stack timeout after #{timeout_in_minutes} minutes"
  end

  def find_stack(stack_name)
    cloud_formation.describe_stacks(stack_name: stack_name).stacks.first
  rescue Aws::CloudFormation::Errors::ValidationError => error
    raise error unless error.message =~ /does not exist/i # may be flaky, do more research in API
    nil
  end

  def all_stack_names
    all_stacks.map{|s| s.stack_name}
  end

  def all_stacks
    cloud_formation.describe_stacks.stacks
  end

  def estimate_template_cost(template, parameters)
    cloud_formation.estimate_template_cost(:template_body => template_body(template), :parameters => transform_parameters(parameters))
  end

  def get_stack_outputs(stack_name)
    stack = find_stack(stack_name)
    fail "stack #{stack_name} not found" unless stack
    transform_outputs(stack.outputs).freeze
  end

  def transform_outputs(outputs)
    outputs.inject({}) { |m, o| m.merge(o.output_key.to_sym => o.output_value) }
  end

  def transform_parameters(parameters)
    parameters.inject([]) { |m, kv| m << {parameter_key: kv[0].to_s, parameter_value: kv[1].to_s} }
  end

  def get_stack_resources(stack_name)
    resources = cloud_formation.describe_stack_resources(stack_name: stack_name).data.stack_resources
    resources.inject({}){|map, resource| map.merge(resource.logical_resource_id.to_sym => resource)}.freeze
  end

  def cloud_formation # lazy CloudFormation client
    @lazy_cloud_formation ||= Aws::CloudFormation::Client.new(cloud_formation_parameters)
  end

  def cloud_formation_parameters
    params = {}
    params[:credentials] = @credentials if @credentials
    params[:region] = @region if @region
    params
  end

  def template_body(template)
    template = File.read(template) if File.exists?(template)
    template.gsub(/(\s*\/\/.*$)|(".*")/) {|m| m[0] == '"' ? m : ''}
  end

  extend self

end

if $0 ==__FILE__ # placeholder for interactive testing
  template = <<-EOL
    bla bla //comment
    bla "//no comment"
    bla // still a "comment"
    bla "some string" // comment
  EOL

  puts Stacker.template_body(template)

end
