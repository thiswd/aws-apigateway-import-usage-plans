require "aws-sdk-apigateway"
require "json"
require 'optparse'

options = {}
OptionParser.new do |opts|
  opts.banner = "Usage: ruby import_usage_plans.rb --region REGION --file FILE"

  opts.on("--region REGION", "AWS Region") do |region|
    options[:region] = region
  end

  opts.on("--file FILE", "Path to the usage_plans.json file") do |file|
    options[:file] = file
  end
end.parse!

if !options[:region] || !options[:file]
  puts "Both --region and --file arguments are required"
  exit
end

input_file = options[:file]

begin
  file = File.read(input_file)
  usage_plans = JSON.parse(file)
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

apigateway = Aws::APIGateway::Client.new(region: options[:region])

usage_plans_count = 0
error_count = 0

usage_plans["items"].each do |plan|
  throttle_params = plan["throttle"] ? {
    burst_limit: plan["throttle"]["burstLimit"].to_i,
    rate_limit: plan["throttle"]["rateLimit"].to_f
  } : nil

  quota_params = plan["quota"] ? {
    limit: plan["quota"]["limit"].to_i,
    offset: plan["quota"]["offset"].to_i,
    period: plan["quota"]["period"]
  } : nil

  begin
    response = apigateway.create_usage_plan({
      name: plan["name"],
      throttle: throttle_params,
      quota: quota_params
    })
    usage_plans_count += 1
  rescue Aws::APIGateway::Errors::ServiceError => e
    puts "Failed to create usage plan: #{e.message}"
    error_count += 1
  end
end

puts "Total usage plans imported: #{api_keys_count}"
puts "Total errors: #{error_count}"

begin
  puts "Deleting #{input_file}..."
  File.delete(input_file)
  puts "#{input_file} has been successfully deleted."
rescue Errno::ENOENT
  puts "Error: The file #{input_file} does not exist."
rescue StandardError => e
  puts "An error occurred while deleting the file #{input_file}: #{e.message}"
end
