# Hosting a simple website on AWS

In this project, we'll be hosting a highly available, and scalable website on Amazon web services (AWS) cloud using the Infrastructure-as-code language, Terraform.

The website will be hosted on apache servers running within the multiple EC2 instances, managed by auto scaling groups, over multiple availability zones. The incoming traffic will be distributed among them with a load balancer.

<p align="center" width="40">
  <img src="https://github.com/jamesantonydas/Hosting_a_website_on_AWS/blob/main/docs/img/banner.png"/>
</p>

## Getting started

To deploy the web page, Please make sure you have an AWS account, and the HashiCorp terraform installed on your computer.

You can download the Terraform from the official source, https://www.terraform.io/

## Setting up the AWS credentials

First, It is important to set the AWS credentials, 
There are two ways to do this,

Method 1: Setting the environment variables by running the commands, (preferably within a virtual environment of the project)

```
export AWS_ACCESS_KEY_ID="your_access_key_here"
export AWS_SECRET_ACCESS_KEY="your_secret_key_here"
```

Method 2: Include your  access key and secret key directly within the terraform code (Not recommended due to security reasons)

```
Provider “aws” {
 region = "us-east-1"
 access_key = "your_access_key_here"
 secret_key = "your_secret_key_here"
}
```

## Initializing the terraform

To Initialize terraform, please run the following command,

```
terraform init
```

## Deploying the web page

Generate the plan by running,


```
terraform plan
```

Deploy the webpage on the cloud by running,

```
terraform apply
```

<p align="center">
  <img src="https://github.com/jamesantonydas/Hosting_a_website_on_AWS/blob/main/docs/img/apply.png"/>
</p>

You can get the link to the website as an output.

## Terminating the website

You can shutdown the webpage and terminate the running instances, simply run,

```
terraform destroy
```

## Network architecture diagram

<p align="center">
  <img src="https://github.com/jamesantonydas/Hosting_a_website_on_AWS/blob/main/docs/img/network.svg"/>
</p>

Please refer to the [Code documentation](https://github.com/jamesantonydas/Hosting_a_website_on_AWS/blob/main/docs/Antony-Das-James_9216076_Cloud%20Programming_P3_S_final_product.pdf) for more information.
