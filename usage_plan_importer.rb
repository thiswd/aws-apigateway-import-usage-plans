require 'aws-sdk-apigateway'
require 'json'
class UsagePlanImporter
  attr_reader :apigateway, :file_path
  def initialize(region, file_path)
    @apigateway = Aws::APIGateway::Client.new(region: region)
    @file_path = file_path
  end

  def import_usage_plans
    usage_plans = read_usage_plans
    usage_plans_count = 0
    error_count = 0

    usage_plans.each do |plan|
      begin
        response = create_usage_plan(plan)
        usage_plans_count += 1
        puts "Created Usage Plan: #{response.id}"
      rescue Aws::APIGateway::Errors::ServiceError => e
        puts "Failed to create usage plan: #{e.message}"
        error_count += 1
      end
    end

    puts "Total usage plans imported: #{usage_plans_count}"
    puts "Total errors: #{error_count}"
  end

  def delete_input_file
    begin
      puts "Deleting #{file_path}..."
      File.delete(file_path)
      puts "#{file_path} has been successfully deleted."
    rescue Errno::ENOENT
      puts "Error: The file #{file_path} does not exist."
    rescue StandardError => e
      puts "An error occurred while deleting the file #{file_path}: #{e.message}"
    end
  end

  private

  def read_usage_plans
    begin
      file = File.read(file_path)
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

    if usage_plans.has_key?("items")
      usage_plans["items"]
    else
      puts "No usage plans found in #{file_path}"
      exit
    end
  end

  def create_usage_plan(plan)
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
end
