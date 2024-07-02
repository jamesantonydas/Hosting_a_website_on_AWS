#!/bin/bash
sudo su -
sudo yum update -y
sudo yum install -y httpd
sudo systemctl start httpd
sudo systemctl enable httpd
cd /var/www/html
sudo curl -O https://raw.githubusercontent.com/jamesantonydas/Hosting_a_website_on_AWS/main/index.html
