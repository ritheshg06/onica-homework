# onica-homework
Homework for an Onica "Cloud Engineer" interview

## Approach
The original assignment gives two options:
1. A "traditional" setup of EC2 instances behind an ELB, serving up a web site that displays "hello world" and the instance ID.
2. A "serverless" setup of an API Gateway with dev/prod Lambdas serving up an API, backed by DynamoDB for record storage.

I chose the first option arbitrarily.

## Architecture
* A public-facing ALB (application load balancer) accepts incoming requests on TCP port 80 (HTTP).
* The ALB exists in a pair of public subnets (for Internet connectivity). The ALB intrinsically has access to all other subnets in the VPC (often-unwritten AWS logic), allowing the ALB to communicate with the private subnets containing the EC2 instances in the Target Group.
* The ALB Target Group is an ASG that accepts incoming requests only from the ALB Security Group (SG).
* A NAT Gateway provides Internet Access for the instances in the private subnet.
* An S3 Service Gateway Endpoint provides direct access to the S3 Amazon Linux package repository.
* Instances in the ASG are configured via a Launch Config and/or Launch Template. Either one can be used, and both are provided.
* EC2 instances are created in a private subnet. The EC2 instances are not connected to any public subnets. In fact, the EC2 instances are not assigned publicly-routable IP addresses, and cannot be reached except via either the ALB for HTTP requests, or the AWS SSM Session Manager (effectively a bastion) for "out of band" SSH. However, the option to specify an IP range for external SSH is provided for demonstration; the EC2 instances must be assigned public EIPs in order to use the external SSH option.
* The ALB Target Group - to which the EC2 fleet's instances are attached via the AutoScaling Group config - defines the ALB health checks aimed at the EC2 instances. If an instance does not respond to multiple HTTP requests with a 200 ("OK"), the instance is terminated. The ASG (auto-scaling group) configuration will replace the terminated instance(s).
* AutoScaling will lower instance count down to 1, or raise up to 3 - one per AZ for a 3-AZ Region - based on the aggregate CPU utilization.

### SSH access
Options for SSH access are provided, but complete setup is left to the end user. Either public EIPs must be attached to the EC2 instances for direct SSH access, or SSM must be configured for SSM Session Manager access. Both of these items are out of scope, but simple enough for the end user to set up.

## Deployment
The simplest deployment - assuming the user has the AWS CLI installed, proper IAM user permissions, etc. - is as follows:
```bash
aws cloudformation create-stack --profile $YOUR_AWS_CREDENTIALS_PROFILE --region $YOUR_REGION --stack-name $YOUR_STACK_NAME --template-body file://ec2-cloudformation.yaml --parameters ParameterKey=KeyName,ParameterValue=$YOUR_EC2_SSH_KEY_NAME --capabilities CAPABILITY_NAMED_IAM
```

## Testing
### CloudFormation Template validation via AWS CLI
```bash
aws cloudformation validate-template --template-body file:///ec2-cloudformation.yaml
```

### In-depth testing via TaskCat
```bash
curl -s https://raw.githubusercontent.com/aws-quickstart/taskcat/master/installer/docker-installer.sh | sh
```
or
```bash
pip3 install taskcat --user # Requires latest Python 3.5+
```

```bash
taskcat -c onica-homework/ec2-cloudformation/ci/taskcat.yml
```

See `./taskcat_outputs/index.html` for results.

## Sources
I relied upon both my own previous work (such as my [CloudFront/WAF CloudFormation template](https://github.com/sskalnik/cloudfront_blueprint)), and the official AWS documentation regarding best-practice AWS standards (such as [the latest guide to bastions... without bastions](https://aws.amazon.com/blogs/infrastructure-and-automation/toward-a-bastion-less-world/)).

### My own resources:
* CloudFront/WAF/etc. CloudFormation template: https://github.com/sskalnik/cloudfront_blueprint

### External resources:
* AWS Systems Manager Session Manager: https://aws.amazon.com/blogs/infrastructure-and-automation/toward-a-bastion-less-world/
* CI/CD pipeline for AWS CloudFormation templates: https://aws.amazon.com/quickstart/architecture/cicd-taskcat/
* TaskCat guide: https://aws.amazon.com/blogs/infrastructure-and-automation/up-your-aws-cloudformation-testing-game-using-taskcat/
