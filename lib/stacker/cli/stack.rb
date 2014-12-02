require 'stacker/version'
require 'stacker/config'
require 'stacker/cloud_stack'
require 'stacker/stack_list'
require 'thor'
require 'yaml'

module Stacker
  class Stack < Thor

    class_option :config_file, :aliases => "-f", :desc => 'Configuration file to use. Defaults to ./.stacker.yml, also looks in ~/ and /etc/stacker.'
    class_option :environments_file, :desc => 'Environments definitions file to use. Defaults to ./environments.yml, also looks in ~/ and /etc/stacker.'
    class_option :stacks_file, :desc => 'Stack definitions file to use. Defaults to ./stacks.yml, also looks in ~/ and /etc/stacker.'
    class_option :access_key_id, :desc => 'Access key ID'
    class_option :secret_access_key, :desc => 'Secret access key'
    class_option :region, :desc => 'AWS region'
    class_option :verbose, :aliases => '-v', :desc => 'Print more stuff'

    desc 'list', 'List CloudFormation stacks'
    method_option :all, :desc => 'List all stacks, including deleted ones', :default => false
    def list
      say "Stacks:", :bold
      stack_table = [[ 'name', 'status', 'created', 'updated', 'deleted' ]]
      StackList.new(options).stack_list.each { |s|
        stack_table << [
          s.stack_name,
          s.stack_status,
          s.creation_time,
          s.last_updated_time,
          s.deletion_time
        ]
      }
      print_table(stack_table)
    end


    desc 'find STACK_NAME', 'List stacks matching the supplied name'
    method_option :all, :desc => 'List all stacks, including deleted ones', :default => false
    def find(stack_name)
      say "Stacks:", :bold
      stack_table = [[ 'name', 'status', 'created', 'updated', 'deleted' ]]
      StackList.new(options).find_stack_by_name(stack_name).each { |s|
        stack_table << [
            s.stack_name,
            s.stack_status,
            s.creation_time,
            s.last_updated_time,
            s.deletion_time
        ]
      }
      print_table(stack_table)
    end


    desc 'dump STACK_NAME', 'Dump raw info for stacks matching the supplied name'
    method_option :all, :desc => 'List all stacks, including deleted ones', :default => false
    def dump(stack_name)
      StackList.new(options).find_stack_by_name(stack_name).each { |stack|
        puts stack.to_yaml
      }
    end


    desc 'build STACK_NAME ENVIRONMENT_TAG TEMPLATE_FILE', 'Create a stack tagged for the given environment'
    method_option :debug, 
      :aliases => '-d', 
      :desc => 'Don\'t actually create the stack', 
      :default => false
    def build(stack_name, environment_tag, template_file)
      stack_info = CloudStack.new(options).build(stack_name, environment_tag, template_file)
      puts "Stack: #{stack_info.to_yaml}"
    rescue Errno::ENOENT => e
      $stderr.puts "ERROR: #{e}"
      exit 1
    end


    desc 'waitfor STACK_NAME [DESIRED_STATE]', 'Wait for a stack to be created, or in specified state'
    method_option :timeout, :desc => 'Seconds to wait before giving up and returning non-zero', :default => 120
    def waitfor(stack_name, desired_state = 'CREATE_COMPLETE')
      say "Wait #{options[:timeout]} seconds for stack #{stack_name} to become #{desired_state}", :bold
      if StackList.new(options).wait_for_stack(stack_name, options['timeout'], desired_state)
        say "Ready", :green
        exit 0
      else
        say "Stack not ready", :red
        exit 1
      end
    end


    desc 'destroy STACK_NAME', 'Delete a stack'
    def destroy(stack_name)
      say "Deleting stack '#{stack_name}':", :bold
      result = CloudStack.new(options).delete(stack_name)
      puts "Result: #{result.to_yaml}"
    end


    private


    def options
      original_options = super
      configuration = Config.new(original_options['config_file']).configuration
      combined_options = configuration.merge(original_options)
      Thor::CoreExt::HashWithIndifferentAccess.new(combined_options)
    rescue Stacker::ConfigurationFileProblem => e
      $stderr.puts "ERROR: #{e}"
      exit 1
    end

  end
end
