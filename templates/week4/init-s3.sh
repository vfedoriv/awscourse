aws s3api create-bucket --bucket vf-s3-bucket-1 \
    --region us-west-2 --profile capgemini --acl private \
    --create-bucket-configuration LocationConstraint=us-west-2

aws s3api put-object --bucket vf-s3-bucket-1 --key scripts/dynamodb-script.sh \
    --body ~/workspace/awscourse/templates/week4/dynamodb-script.sh --profile capgemini

aws s3api put-object --bucket vf-s3-bucket-1 --key scripts/rds-script.sql \
    --body ~/workspace/awscourse/templates/week4/rds-script.sql --profile capgemini