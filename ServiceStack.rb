
require_relative 'Stacker.rb'

module ServiceStack

  # include GenericStack ???

  class << self
    attr_writer :name, :sandbox, :version
  end

  def self.stack_name
    fail 'name not set' if name.nil? || name.empty?
    (sandbox ? "#{sandbox}-" : '') + name
  end

  def self.name
    @name ||= SERVICE_NAME
  end

  def self.sandbox
    @sandbox ||= SERVICE_SANDBOX
  end

  def self.version
    @version ||= SERVICE_VERSION
  end

  def self.global_stack_name
    @global_stack ||= 'global'
  end

  def self.create_or_update(template, parameters)
    Stacker.get_stack_outputs(global_stack_name, parameters)
    parameters[:ServiceVersion] = version
    Stacker.create_or_update_stack(stack_name, template, parameters)
  end

  def self.delete
    Stacker.delete_stack(stack_name)
  end

  def self.outputs
    @lazy_outputs ||= Stacker.get_stack_outputs(stack_name)
  end
end