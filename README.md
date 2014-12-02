# Stacker

Stacker is a command-line utility to manage AWS CloudFormation stacks according
to the standards and conventions for our platform.

A "stack" is a group of one or more server instances and related resources which
are managed as a group. A given stack exists inside an environment, where it may
integrate with other resources.

Capabilities provided by stacker will include:

- Build a stack
- Destroy a stack
- Update a stack (?)
- Recover a stack
- Replace a stack (destroy and build, potentially using the "Phoenix" pattern)

## Phoenix pattern

The phoenix pattern is a technique to replace a running stack with zero or minimal
downtime, with an opportunity for easy rollback. The stages for replacing the 
stack are:

1. Create a new stack in standby mode (not actively used by consumers)
2. Validate the new stack
3. Switch the new stack into active mode (switching the existing stack to standby)
4. Validate consumers are using the new stack successfully
5. Destroy the old stack

If validation fails, the switchover can be reversed to keep the existing stack
running.

The stacker tool doesn't carry out validation, it only provides the opportunity
for it to take place.

## AMI selection

Stacker assumes AMIs have been tagged following certain conventions to indicate
which AMI is to be used when building a new stack.

## Installation

This project creates a gemfile. Ideally it will be deployed to a gem server or
S3 so it can be installed on servers that carry out stack management tasks.

## Usage

    stack help
