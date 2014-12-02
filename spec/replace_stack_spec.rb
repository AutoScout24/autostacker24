# require 'spec_helper'
# require 'stacker/environments'
# require 'stacker/stack_template'
# require 'stacker/stack_list'
# require 'stacker/cloud_stack'
# require 'stacker/config'
# require 'yaml'

# describe 'An existing stack' do

#   before(:all) do
#     @options = Stacker::Config.new().configuration
#     @options['template_dir'] = 'templates'

#     first_build_id = Time.now.strftime("%Y%m%d%H%M%S")
#     @first_stack_name = "basic-stacktest-#{first_build_id}"
#     $stderr.puts "INFO: Building first stack #{@first_stack_name}"
#     cloud_stack = Stacker::CloudStack.new(@options)
#     @first_stack_info = cloud_stack.build('basic', 'stacktest', first_build_id)
#     Stacker::StackList.new(@options).wait_for_stack(@first_stack_name, 120, ['CREATE_COMPLETE'])


#     replacement_build_id = Time.now.strftime("%Y%m%d%H%M%S")
#     @replacement_stack_name = "basic-stacktest-#{replacement_build_id}"
#     $stderr.puts "INFO: Building replacement stack #{@replacement_stack_name}"
#     cloud_stack = Stacker::CloudStack.new(@options)
#     @replacement_stack_info = cloud_stack.build('basic', 'stacktest', replacement_build_id)
#     Stacker::StackList.new(@options).wait_for_stack(@replacement_stack_name, 120, ['CREATE_COMPLETE'])


#   end

#   it 'should be replaced' do
#     new_biuld
#   end


#   after(:all) do
#     unless @first_stack_info.nil?
#       Stacker::CloudStack.new(@options).delete(@first_stack_name)
#       $stderr.puts "INFO: Requesting destruction of stack #{@first_stack_name}, waiting"
#       Stacker::StackList.new(@options).wait_for_stack(@first_stack_name, 120, ['DELETE_COMPLETE']).should be_true
#       $stderr.puts "INFO: Stack destroyed"
#     end
#   end

# end
