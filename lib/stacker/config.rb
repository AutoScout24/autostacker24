require 'yaml'

module Stacker

  class ConfigurationFileProblem < StandardError; end

  class Config

    attr_reader :configuration

    def initialize(filename = nil)
      config_file = filename || find_config_file
      # $stderr.puts "INFO: configuration file: #{config_file}"
      @configuration = ::YAML::load_file(config_file)
      raise ConfigurationFileProblem.new("Failed to read configuration file #{config_file}") if @configuration.nil?
    end

    def find_config_file
      cwd = Dir.getwd
      if File.exists?(File.join(Dir.getwd, '.stacker.yml'))
        File.join(Dir.getwd, '.stacker.yml')
      elsif File.exists?(File.join(Dir.home, '.stacker.yml'))
        File.join(Dir.home, '.stacker.yml')
      elsif File.exists?(File.join('/etc', 'stacker', 'stacker.yml'))
        File.join('/etc', 'stacker', '.stacker.yml')
      else
        raise ConfigurationFileProblem.new('Could not find stacker config file')
      end
    end

  end

end
