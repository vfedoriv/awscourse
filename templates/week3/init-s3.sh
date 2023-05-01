echo "Test file content" > ~/workspace/awscourse/templates/week3/test1.txt

aws s3api create-bucket --bucket vf-s3-bucket-1 \
    --region us-west-2 --profile capgemini --acl private \
    --create-bucket-configuration LocationConstraint=us-west-2

aws s3api put-bucket-versioning --bucket vf-s3-bucket-1 \
    --region us-west-2 --profile capgemini \
    --versioning-configuration Status=Enabled

aws s3api put-object --bucket vf-s3-bucket-1 --key dir1/test1.txt \
    --body ~/workspace/awscourse/templates/week3/test1.txt --profile capgemini