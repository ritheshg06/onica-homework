#!/bin/bash -xe

# Userdata guide: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html
# LAMP / Apache on Amazon Linux 2 guide: https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-lamp-amazon-linux-2.html

# Wait for IP address to be assigned to interface eth0
while ! ifconfig | grep -F "10.10." > /dev/null; do sleep 5; done
# Get latest updates
yum update -y
# Install Apache (HTTPS daemon)
yum install httpd -y
# Make the default "ec2-user" account part of the "apache" group
usermod -a -G apache ec2-user
# Give ec2-user control over the Apache resource directory...
chown -R ec2-user:apache /var/www
# ... and subdirectories
chmod 2775 /var/www && find /var/www -type d -exec chmod 2775 {} \;
# ... and files
find /var/www -type f -exec chmod 0664 {} \;
# Create a default web page
touch /var/www/html/index.html
# Add the required message per the Onica homework assignment
echo "hello world from $(hostname)" > /var/www/html/index.html
# Set index.html permissions for global read
chmod 755 index.html
# Start the Apache server
service httpd start
# (Optional) Make sure Apache will start up again if the httpd service or the EC2 instance are restarted
chkconfig --add httpd
chkconfig httpd on
