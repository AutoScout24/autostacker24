require 'json'
require_relative 'stacker.rb'

class ServiceStack

  def initialize(name, version, sandbox = nil, global_stack_name = nil)
    @name = name || fail('mandatory name is not specified')
    @version = version || ENV['VERSION'] || fail('mandatory version is not specified')
    @sandbox = sandbox || ENV['SANDBOX']
    @stack_name = (sandbox ? "#{sandbox}-" : '') + name
    @global_stack_name  = global_stack_name || ENV['GLOBAL_STACK_NAME'] || 'global'
  end

  attr_reader :name, :sandbox, :version, :stack_name, :global_stack_name

  def create_or_update(template, parameters)
    inputs = JSON(template)['Parameters']
    global_outputs.each{|k, v| parameters[k.to_sym] = v if inputs.has_key?(k.to_s)}
    parameters[:Version] = version
    Stacker.create_or_update_stack(stack_name, template, parameters)
  end

  def delete
    Stacker.delete_stack(stack_name)
  end

  def outputs
    @lazy_outputs ||= Stacker.get_stack_outputs(stack_name)
  end

  def global_outputs
    @lazy_global_outputs ||= Stacker.get_stack_outputs(global_stack_name)
  end

  def estimate(template, parameters)
    Stacker.estimate_template_cost(template, parameters)
  end

end

if $0 ==__FILE__ # placeholder for interactive testing

end
