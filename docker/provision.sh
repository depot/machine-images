#!/bin/bash
set -ex

# Update software
yum update -y
yum install -y git

# Disable unnecessary services
systemctl disable postfix.service
systemctl disable update-motd.service

# Install Docker
amazon-linux-extras install docker
service docker start
systemctl enable docker
usermod -a -G docker ec2-user
