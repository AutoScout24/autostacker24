require 'aws-sdk'

module Stacker

  def self.create_or_update_stack(stack_name, template_body, parameters)
    if find_stack(stack_name).nil?
      create_stack(stack_name, template_body, parameters)
    else
      update_stack(stack_name, template_body, parameters)
    end
  end

  def self.create_stack(stack_name, template_body, parameters)
    cloud_formation.create_stack(stack_name:    stack_name,
                                 template_body: template_body,
                                 on_failure:    'DELETE',
                                 parameters:    transform_parameters(parameters),
                                 capabilities:  ['CAPABILITY_IAM'])
    wait_for_stack(stack_name, :create)
  end

  def self.update_stack(stack_name, template_body, parameters)
    begin
      cloud_formation.update_stack(stack_name:    stack_name,
                                   template_body: template_body,
                                   parameters:    transform_parameters(parameters),
                                   capabilities:  ['CAPABILITY_IAM'])
    rescue Aws::CloudFormation::Errors::ValidationError => error
      raise error unless error.message =~ /No updates are to be performed/i # may be flaky, do more research in API
      find_stack(stack_name)
    else
      wait_for_stack(stack_name, :update)
    end
  end

  def self.delete_stack(stack_name)
    cloud_formation.delete_stack(stack_name: stack_name)
    wait_for_stack(stack_name, :delete)
  end

  def self.wait_for_stack(stack_name, operation, timeout_in_minutes = 15)
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

  def self.find_stack(stack_name)
    cloud_formation.describe_stacks(stack_name: stack_name).stacks.first
  rescue Aws::CloudFormation::Errors::ValidationError => error
    raise error unless error.message =~ /does not exist/i # may be flaky, do more research in API
    nil
  end

  def self.get_stack_outputs(stack_name, hash = {})
    stack = find_stack(stack_name)
    fail "stack #{stack_name} not found" unless stack
    transform_outputs(stack.outputs, hash)
  end

  def self.transform_outputs(outputs, existing_outputs = {})
    outputs.inject(existing_outputs) { |m, o| m.merge(o.output_key.to_sym => o.output_value) }
  end

  def self.transform_parameters(parameters)
    parameters.inject([]) { |m, kv| m << {parameter_key: kv[0].to_s, parameter_value: kv[1].to_s} }
  end

  def self.sandboxed_stack_name(sandbox, stack_name)
    (sandbox ? "#{sandbox}-" : '') + stack_name
  end

  def self.get_stack_resources(stack_name, logical_resource_id)
    cloud_formation.describe_stack_resources(stack_name: stack_name).data.stack_resources.select{|p| p.logical_resource_id == logical_resource_id}.first

    # maybe we want to return something like a mop from logical_resource_id -> resource, if more than one resource is interesting
    # resources = cloud_formation.describe_stack_resources(stack_name: stack_name).data.stack_resources
    # resources.inject({}){|map, resource| map.merge(resource.logical_resource_id => resource)}

  rescue Aws::CloudFormation::Errors::ValidationError => error
    raise error unless error.message =~ /does not exist/i # may be flaky, do more research in API
    nil
  end

  def self.estimate_template_cost(template_body, parameters)
    cloud_formation.estimate_template_cost(:template_body => template_body, :parameters => transform_parameters(parameters))
  end

  def self.cloud_formation # lazy CloudFormation client
    @lazy_cloud_formation ||= Aws::CloudFormation::Client.new(region: ENV['AWS_DEFAULT_REGION'] || 'eu-west-1')
  end

end

if $0 ==__FILE__ # placeholder for interactive testing

end
