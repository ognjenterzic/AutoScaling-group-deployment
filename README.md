# AutoScaling-group-deployment
I have used Terraform/AWS to deploy autoscaling group


Purpose of this project was to create autoscaling group with all dependant resources like load balancer, target group etc.
EC2 instances are created with already defined launch template. I have created security group for load balancer, load balancer and target group.
They are intended to be empty since when I run `terraform apply --auto-approve` with autoscaling policy two instances are going to be created and placed inside target group.
