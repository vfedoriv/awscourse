#!/bin/bash
sudo su
export AWS_ACCESS_KEY_ID=${key_id}
export AWS_SECRET_ACCESS_KEY=${key_secret}
export AWS_DEFAULT_REGION=us-west-2
yum update -y
yum install java-1.8.0-amazon-corretto.x86_64 -y
aws s3 cp s3://vf-s3-bucket-1/jars/calc-2021-0.0.2-SNAPSHOT.jar /home/ec2-user/calc-2021-0.0.2-SNAPSHOT.jar
aws s3 cp s3://vf-s3-bucket-1/vf_cap1.pem /home/ec2-user/vf_cap1.pem
cd /home/ec2-user
java -jar calc-2021-0.0.2-SNAPSHOT.jar