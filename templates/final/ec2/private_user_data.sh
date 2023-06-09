#!/bin/bash
sudo su
export AWS_ACCESS_KEY_ID=${key_id}
export AWS_SECRET_ACCESS_KEY=${key_secret}
export AWS_DEFAULT_REGION=us-west-2
export RDS_HOST=${rds_address}
yum update -y
yum install java-1.8.0-amazon-corretto.x86_64 -y
dnf install postgresql15 -y
aws s3 cp s3://vf-s3-bucket-1/jars/persist3-2021-0.0.1-SNAPSHOT.jar /home/ec2-user/persist3-2021-0.0.1-SNAPSHOT.jar
cd /home/ec2-user
java -jar persist3-2021-0.0.1-SNAPSHOT.jar