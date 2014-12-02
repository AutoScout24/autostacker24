require 'aws-sdk'
require 'yaml'

module Stacker

  class StackList

    def initialize(options)
      @options = options
      credentials = Aws::Credentials.new(options['access_key_id'], options['secret_access_key'])
      @cf_client = Aws::CloudFormation::Client.new(
          region: options['region'],
          credentials: credentials
      )
    end

    def stack_list
      if @options[:all]
        all_stacks
      else
        undeleted_stacks
      end
    end

    def find_stack_by_name(name)
      stack_list.select { |stack|
        stack.stack_name == name
      }
    end

    def wait_for_stack(stack_name, timeout, desired_status)
      $stderr.puts "INFO: Wait #{timeout} seconds for stack #{stack_name} to become #{desired_status}"

      start_time = Time.now
      while Time.now - start_time < timeout.to_f
        if ! filtered_stacks([desired_status]).select { |stack|
          stack.stack_name == stack_name
        }.empty?
          $stderr.puts "INFO: stack #{stack_name} entered requested status within #{Time.now - start_time} seconds"
          return true
        end
        sleep(5)
      end

      $stderr.puts "WARN: Stack #{stack_name} has not entered a requested status after #{timeout} seconds"
      false
    end

    def all_stacks
      @cf_client.list_stacks.map { |response|
        response.stack_summaries.map { |ss| ss }
      }.flatten
    end

    def undeleted_stacks
      @cf_client.list_stacks(stack_status_filter: undeleted_filter).map { |response|
        response.stack_summaries.map { |ss| ss }
      }.flatten
    end

    def filtered_stacks(status)
      @cf_client.list_stacks(stack_status_filter: status).map { |response|
        response.stack_summaries.map { |ss| ss }
      }.flatten
    end

    def undeleted_filter
      [
        'CREATE_IN_PROGRESS',
        'CREATE_FAILED',
        'CREATE_COMPLETE',
        'ROLLBACK_IN_PROGRESS',
        'ROLLBACK_FAILED',
        'ROLLBACK_COMPLETE',
        'DELETE_IN_PROGRESS',
        'DELETE_FAILED',
        'UPDATE_IN_PROGRESS',
        'UPDATE_COMPLETE_CLEANUP_IN_PROGRESS',
        'UPDATE_COMPLETE',
        'UPDATE_ROLLBACK_IN_PROGRESS',
        'UPDATE_ROLLBACK_FAILED',
        'UPDATE_ROLLBACK_COMPLETE_CLEANUP_IN_PROGRESS',
        'UPDATE_ROLLBACK_COMPLETE'
      ]
    end

  end

end
