# Avora | My First Major AWS Infrastructure Project

Avora is a fictional healthcare appointment application that I used to put my AWS and Terraform knowledge into practice.

For this project, I focused on the cloud infrastructure rather than frontend development. I used Terraform to provision the AWS resources needed to host the application, make it accessible over the internet and maintain multiple running instances.

I wanted to understand what goes into deploying an application beyond simply getting it to run. This meant working with networking, compute, storage, permissions, load balancing and instance recovery.

## What I Worked On

I started by setting up a VPC with two public subnets in different Availability Zones. I then configured the internet gateway, route table and security group needed for connectivity.

For application hosting, I used EC2 instances running Amazon Linux 2023 and Nginx. The application files were stored in a private S3 bucket, with an IAM role allowing the instances to retrieve them.

I configured an Application Load Balancer to distribute incoming requests across the instances and an Auto Scaling Group to maintain two running instances.

I also used Systems Manager Session Manager to access the EC2 instances without opening SSH access.

All the infrastructure was defined and deployed using Terraform.

## Testing Instance Recovery

I wanted to see what would happen if one of the instances stopped running.

To test this, I deliberately terminated one of the EC2 instances without changing the Auto Scaling Group's desired capacity.

The group detected the termination and launched a replacement instance. I checked that the replacement registered with the target group, that both instances were healthy and that the application was still accessible through the load balancer.

This was one of the parts of the project that helped me understand the practical value of Auto Scaling.

## What I Took Away

This project helped me connect several AWS concepts that I had previously studied separately.

I got to work with Terraform beyond basic configuration, troubleshoot networking and deployment issues, manage permissions between AWS services and test how infrastructure responds when an instance is terminated.

I also learned that getting a deployment to work involves more than writing configuration files. You have to understand how the resources depend on each other and be able to troubleshoot when something doesn't work as expected.

## Technologies and Services

**Infrastructure as Code:** Terraform

**Compute:** Amazon EC2

**Networking:** Amazon VPC, Public Subnets, Internet Gateway

**Load Balancing and Scaling:** Application Load Balancer, Target Groups, Auto Scaling Groups

**Storage:** Amazon S3

**Access Management:** IAM

**Instance Management:** AWS Systems Manager Session Manager

**Web Server:** Nginx

**Frontend:** HTML, CSS and JavaScript (provided application)

## Project Structure

The `app` folder contains the application files used for deployment.

The `docs` folder contains the architecture documentation.

The `infra` folder contains the Terraform configuration used to create and manage the AWS resources.

The root directory contains the main project README and Git ignore configuration.

## Running the Project

Requirements: an AWS account, AWS CLI, Terraform 1.5 or later, and Git.

Clone the repository:

```bash
git clone https://github.com/dansowaaaa/avora_healthcare.git
cd avora_healthcare
```

Move into the infrastructure directory:

```bash
cd infra
```

Initialise Terraform:

```bash
terraform init
```

Create a local variables file:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Format and validate the configuration:

```bash
terraform fmt -recursive
terraform validate
```

Review the planned changes:

```bash
terraform plan
```

Deploy the infrastructure:

```bash
terraform apply
```

When finished, remove the resources to avoid ongoing AWS charges:

```bash
terraform destroy
```

## Application Limitations

Avora is a demonstration application. It uses fictional healthcare professionals, and appointment information and notes are stored in browser local storage.

It does not include a backend, database, real authentication or secure patient-record storage. It should not be used with real patient information.

## Future Improvements

Some areas I would like to explore next include CI/CD, monitoring, automated testing and dynamic scaling.

## Links

**Live application:** http://avora-alb-461228676.us-east-1.elb.amazonaws.com

**GitHub repository:** https://github.com/dansowaaaa/avora_healthcare

Built by Phyllis Danso
