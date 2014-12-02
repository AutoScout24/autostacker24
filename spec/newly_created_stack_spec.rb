# require 'spec_helper'
# require 'stacker/stack_list'
# require 'stacker/cloud_stack'
# require 'stacker/config'
# require 'yaml'

# describe 'A newly created stack' do

#   before(:all) do
#     @options = Stacker::Config.new().configuration
#     @options['template_dir'] = 'templates'

#     build_id = Time.now.strftime("%Y%m%d%H%M%S")
#     @stack_name = "basic-stacktest-#{build_id}"
#     $stderr.puts "INFO: Building stack #{@stack_name}"
#     cloud_stack = Stacker::CloudStack.new(@options)
#     @stack_info = cloud_stack.build('basic', 'stacktest', build_id)
#   end

#   it 'should have stuff in it' do
#     @stack_info.should_not be_nil
#   end

#   it 'should appear in the list of stacks' do
#     Stacker::StackList.new(@options).wait_for_stack(@stack_name, 120, ['CREATE_COMPLETE']).should be_true
#   end

#   after(:all) do
#     unless @stack_info.nil?
#       Stacker::CloudStack.new(@options).delete(@stack_name)
#       $stderr.puts "INFO: Requesting destruction of stack #{@stack_name}, waiting"
#       Stacker::StackList.new(@options).wait_for_stack(@stack_name, 120, ['DELETE_COMPLETE']).should be_true
#       $stderr.puts "INFO: Stack destroyed"
#     end
#   end

# end
