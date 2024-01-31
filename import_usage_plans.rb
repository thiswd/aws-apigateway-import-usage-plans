require 'optparse'
require_relative 'usage_plan_importer'
def parse_arguments
  options = {}
  OptionParser.new do |opts|
    opts.banner = "Usage: ruby import_usage_plans.rb --region REGION --file FILE"

    opts.on("--region REGION", "AWS Region") { |region| options[:region] = region }
    opts.on("--file FILE", "Path to the usage_plans.json file") { |file| options[:file] = file }
  end.parse!

  unless options[:region] && options[:file]
    puts "Both --region and --file arguments are required"
    exit
  end

  options
end

options = parse_arguments
importer = UsagePlanImporter.new(options[:region], options[:file])
importer.import_usage_plans
importer.delete_input_file
