# onica-homework
Homework for an Onica "Cloud Engineer" interview

## Approach
The original assignment gives two options:
1. A "traditional" setup of EC2 instances behind an ELB, serving up a web site that displays "hello world" and the instance ID.
2. A "serverless" setup of an API Gateway with dev/prod Lambdas serving up an API, backed by DynamoDB for record storage.

I chose the first option arbitrarily.

## Architecture
A public-facing ALB (application load balancer) accepts incoming requests on TCP port 80 (HTTP).
EC2 instances in a private subnet are attached to the ALB via the intrinsic rule that an ELB associated with a VPC can communicate with *any* subnet in that VPC. The EC2 instances are not connected to any public subnets. In fact, the EC2 instances are not assigned publicly-routable IP addresses, and cannot be reached except via either the ALB for HTTP requests, or the AWS SSM Session Manager (effectively a bastion) for "out of band" SSH.
The ALB Target Group - to which the EC2 fleet's instances are attached via the AutoScaling Group config - defines the ALB health checks aimed at the EC2 instances. If an instance does not respond to multiple HTTP requests with a 200 ("OK"), the instance is terminated. The ASG (auto-scaling group) configuration will replace the terminated instance(s).
The EC2 instances' Security Group only allows incoming traffic from the ALB (by trusting the ALB's Security Group, not by a hard-coded IP of the ALB) over HTTP (TCP port 80).

## Deployment
The simplest deployment - assuming the user has the AWS CLI installed, proper IAM user permissions, etc. - is as follows:
```bash
aws cloudformation create-stack --profile $YOUR_AWS_CREDENTIALS_PROFILE --region $YOUR_REGION --stack-name $YOUR_STACK_NAME --template-body file://ec2-cloudformation.yaml --parameters ParameterKey=KeyName,ParameterValue=$YOUR_EC2_SSH_KEY_NAME --capabilities CAPABILITY_NAMED_IAM
```

## Testing

## Features

## Sources
I relied upon both my own previous work (such as my [CloudFront/WAF CloudFormation template](https://github.com/sskalnik/cloudfront_blueprint)), and the official AWS documentation regarding best-practice AWS standards (such as [the latest guide to bastions... without bastions](https://aws.amazon.com/blogs/infrastructure-and-automation/toward-a-bastion-less-world/)).

### My own resources:
* CloudFront/WAF/etc. CloudFormation template: https://github.com/sskalnik/cloudfront_blueprint
* Elastic Beanstalk (subset of CloudFormation) load-balanced web site project: https://github.com/sskalnik/stelligent

### External resources:
* AWS Systems Manager Session Manager: https://aws.amazon.com/blogs/infrastructure-and-automation/toward-a-bastion-less-world/
* CI/CD pipeline for AWS CloudFormation templates: https://aws.amazon.com/quickstart/architecture/cicd-taskcat/
