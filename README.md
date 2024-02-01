# Usage Plan Importer

This tool facilitates the importation of AWS API Gateway usage plans from a JSON file into your AWS account, streamlining the management and replication of usage plans across environments.

## Features

- Import usage plans from a JSON file to AWS API Gateway.
- Command-line interface for specifying AWS region and input file path.
- Automated deletion of the input file after successful import.
- Error handling for AWS service errors and file processing issues.

## Requirements

- AWS CLI
- AWS SDK for Ruby (`aws-sdk-apigateway`)
- Ruby

## Setup

Ensure AWS CLI and Ruby are installed on your system, and you have configured your AWS credentials.

Install the required Ruby gems:

```bash
gem install aws-sdk-apigateway
```

## Usage

### Generating the Input File

First, generate a `usage_plans.json` file using the AWS CLI:

```bash
aws apigateway get-usage-plans > <PathToUsagePlansJson>
```

### Running the Importer

Navigate to the directory containing `import_usage_plans.rb` and execute the script with the required options:

```bash
ruby import_usage_plans.rb --region <YourAWSRegion> --file <PathToUsagePlansJson>
```

- **--region**: The AWS region where the usage plans will be imported.
- **--file**: The path to the `usage_plans.json` file.
