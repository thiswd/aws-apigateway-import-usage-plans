require "aws-sdk-apigateway"
require "json"
require 'optparse'

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

def read_usage_plans(file_path)
  begin
    file = File.read(file_path)
    JSON.parse(file)
  rescue Errno::ENOENT => e
    puts "Error: File not found - #{e.message}"
    exit
  rescue Errno::EACCES => e
    puts "Error: File not accessible - #{e.message}"
    exit
  rescue JSON::ParserError => e
    puts "Error: File content is not valid JSON - #{e.message}"
    exit
  rescue StandardError => e
    puts "An unexpected error occurred - #{e.message}"
    exit
  end
end

def create_usage_plan(apigateway, plan)
  throttle_params = plan["throttle"] ? {
    burst_limit: plan["throttle"]["burstLimit"].to_i,
    rate_limit: plan["throttle"]["rateLimit"].to_f
  } : nil

  quota_params = plan["quota"] ? {
    limit: plan["quota"]["limit"].to_i,
    offset: plan["quota"]["offset"].to_i,
    period: plan["quota"]["period"]
  } : nil

  apigateway.create_usage_plan({
    name: plan["name"],
    throttle: throttle_params,
    quota: quota_params
  })
end

def delete_file(file_path)
  begin
    File.delete(file_path)
    puts "#{file_path} has been successfully deleted."
  rescue Errno::ENOENT
    puts "Error: The file #{file_path} does not exist."
  rescue StandardError => e
    puts "An error occurred while deleting the file #{file_path}: #{e.message}"
  end
end

options = parse_arguments
usage_plans = read_usage_plans(options[:file])
apigateway = Aws::APIGateway::Client.new(region: options[:region])

usage_plans_count = 0
error_count = 0

usage_plans["items"].each do |plan|
  begin
    response = create_usage_plan(apigateway, plan)
    usage_plans_count += 1
    puts "Created Usage Plan: #{response.id}"
  rescue Aws::APIGateway::Errors::ServiceError => e
    puts "Failed to create usage plan: #{e.message}"
    error_count += 1
  end
end

puts "Total usage plans imported: #{usage_plans_count}"
puts "Total errors: #{error_count}"

delete_file(options[:file])
