#!/bin/bash
# Update & install Apache
yum update -y
yum install -y httpd

# Simple web page
echo "<h1>New version deployed 🚀</h1><p>Hello from $(hostname)</p>" > /var/www/html/index.html


# Enable & start web server
systemctl enable httpd
systemctl start httpd
