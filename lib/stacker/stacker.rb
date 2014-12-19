require 'aws-sdk'

class Stacker

  @@account_hash = {
    'as24prod' => '037251718545',
    'as24dev'  => '544725753551'
  }

  def initialize(options = {})
    @target_account_number = @@account_hash[options[:target_account]]
    @target_role = options[:target_role] || get_role
  end

  def get_role
    arn = Aws::IAM::Client.new.get_user.user.arn
    type = arn.split(':')[5].split('/')[0]
    if type == 'role'
      arn.split(':')[5].split('/')[1]
    end
  end

  def get_account
    Aws::IAM::Client.new.get_user.user.arn.split(':')[4]
  end

  def create_or_update_stack(stack_name, template_body, parameters)
    if find_stack(stack_name).nil?
      create_stack(stack_name, template_body, parameters)
    else
      update_stack(stack_name, template_body, parameters)
    end
  end

  def create_stack(stack_name, template_body, parameters)
    cloud_formation.create_stack(stack_name:    stack_name,
                                 template_body: template_body,
                                 on_failure:    'DELETE',
                                 parameters:    transform_parameters(parameters),
                                 capabilities:  ['CAPABILITY_IAM'])
    wait_for_stack(stack_name, :create)
  end

  def update_stack(stack_name, template_body, parameters)
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

  def delete_stack(stack_name)
    cloud_formation.delete_stack(stack_name: stack_name)
    wait_for_stack(stack_name, :delete)
  end

  def wait_for_stack(stack_name, operation, timeout_in_minutes = 15)
    stop_time = Time.now + timeout_in_minutes * 60
    finished = /(CREATE_COMPLETE|UPDATE_COMPLETE|DELETE_COMPLETE|ROLLBACK_COMPLETE|ROLLBACK_FAILED|CREATE_FAILED)$/
    while Time.now < stop_time
      stack = find_stack(stack_name)
      status = stack ? stack.stack_status : 'DELETE_COMPLETE'
      expected_status = case operation
                          when :create then /CREATE_COMPLETE$/
                          when :update then /UPDATE_COMPLETE$/
                          when :delete then /DELETE_COMPLETE$/
                        end
      return true if status =~ expected_status
      fail "waiting for stack #{stack_name} failed, current status #{status}" if status =~ finished
      sleep(5)
    end
    fail "waiting for stack timeout after #{timeout_in_minutes} minutes"
  end

  def find_stack(stack_name)
    cloud_formation.describe_stacks(stack_name: stack_name).stacks.first
  rescue Aws::CloudFormation::Errors::ValidationError => error
    raise error unless error.message =~ /does not exist/i # may be flaky, do more research in API
    nil
  end

  def get_stack_outputs(stack_name, hash = {})
    stack = find_stack(stack_name)
    fail "stack #{stack_name} not found" unless stack
    transform_outputs(stack.outputs, hash)
  end

  def transform_outputs(outputs, existing_outputs = {})
    outputs.inject(existing_outputs) { |m, o| m.merge(o.output_key.to_sym => o.output_value) }
  end

  def transform_parameters(parameters)
    parameters.inject([]) { |m, kv| m << {parameter_key: kv[0].to_s, parameter_value: kv[1].to_s} }
  end

  def sandboxed_stack_name(sandbox, stack_name)
    (sandbox ? "#{sandbox}-" : '') + stack_name
  end

  def get_stack_resources(stack_name, logical_resource_id)
    cloud_formation.describe_stack_resources(stack_name: stack_name).data.stack_resources.select{|p| p.logical_resource_id == logical_resource_id}.first

    # maybe we want to return something like a mop from logical_resource_id -> resource, if more than one resource is interesting
    # resources = cloud_formation.describe_stack_resources(stack_name: stack_name).data.stack_resources
    # resources.inject({}){|map, resource| map.merge(resource.logical_resource_id => resource)}

  rescue Aws::CloudFormation::Errors::ValidationError => error
    raise error unless error.message =~ /does not exist/i # may be flaky, do more research in API
    nil
  end

  def estimate_template_cost(template_body, parameters)
    cloud_formation.estimate_template_cost(:template_body => template_body, :parameters => transform_parameters(parameters))
  end

  def cloud_formation # lazy CloudFormation client
    if get_account == @target_account_number
        @lazy_cloud_formation ||= Aws::CloudFormation::Client.new(:region => ENV['AWS_DEFAULT_REGION'] || 'eu-west-1')
    else if @target_account_number.nil? || @target_role.nil?
      if @target_account_number && @target_role.nil?
        # Seems to be a user. Target account given, but no role"
        fail "Cannot assume unknown role in target account #{@target_account_number}"
      else
        # Normal case, user with own credentials is doing something. No role assumption needed
        @lazy_cloud_formation ||= Aws::CloudFormation::Client.new(:region => ENV['AWS_DEFAULT_REGION'] || 'eu-west-1')
      end
    else
        # Target account is set and target role also (or current caller is actually a role)
        role_arn = "arn:aws:iam::#{@target_account_number}:role/#{@target_role}"
        role_credentials = Aws::AssumeRoleCredentials.new(client: Aws::STS::Client.new, :role_arn => role_arn, :role_session_name => 'stacker')
        @lazy_cloud_formation ||= Aws::CloudFormation::Client.new(:credentials => role_credentials, :region => ENV['AWS_DEFAULT_REGION'] || 'eu-west-1')
    end
  end
end

if $0 ==__FILE__ # placeholder for interactive testing

end
