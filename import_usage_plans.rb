require 'optparse'
require_relative 'lib/usage_plan_importer'

class ImportUsagePlans
  USAGE_INSTRUCTION = "Usage: ruby import_usage_plans.rb --region REGION --file FILE".freeze

  def self.run
    options = parse_arguments
    importer = UsagePlanImporter.new(options[:region], options[:file])
    importer.execute
  end

  private

  def self.parse_arguments
    options = {}
    OptionParser.new do |opts|
      opts.banner = USAGE_INSTRUCTION

      opts.on("--region REGION", "AWS Region") { |region| options[:region] = region }
      opts.on("--file FILE", "Path to the usage_plans.json file") { |file| options[:file] = file }
    end.parse!

    validate_arguments(options)
    options
  end

  def self.validate_arguments(options)
    missing_args = []
    missing_args << '--region' unless options[:region]
    missing_args << '--file' unless options[:file]

    if missing_args.any?
      puts "Missing arguments: #{missing_args.join(', ')}"
      puts USAGE_INSTRUCTION
      exit
    end
  end
end

ImportUsagePlans.run
