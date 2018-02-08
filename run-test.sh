#!/bin/bash

prefix=$1

if [ ! -n "$prefix" ]; then
  echo "Usage is ./run-test.sh [resource prefix]"
  exit 1
fi

getStackOutput() {
  local stack=$1
  local key=$2

  local temp=`aws cloudformation describe-stacks --stack-name "$stack" --query "Stacks[0].Outputs[?OutputKey=='$key'].OutputValue | [0]"`
  echo "$temp" | sed -e 's/^"//' -e 's/"$//'
}

role_stack="$prefix-roles"
lambda_stack="$prefix-lambda"

echo "Deploying Role Stack as $role_stack"

aws cloudformation deploy \
    --template-file ./role.yml \
    --stack-name "$role_stack" \
    --capabilities CAPABILITY_NAMED_IAM \
    --parameter-overrides Prefix="$prefix"

cfn_role=`getStackOutput $role_stack CfnRoleArn`

echo "Deploying lambda stack as $lambda_stack with role $cfn_role"

aws cloudformation deploy \
    --template-file ./lambda.yml \
    --stack-name "$lambda_stack" \
    --parameter-overrides Prefix="$prefix" \
    --tags foo=bar \
    --role-arn "$cfn_role"

lambda_arn=`getStackOutput $lambda_stack LambdaArn`

echo "  Done with initial deploy of lambda stack"

echo "Lambda stack messages:"
aws cloudformation describe-stack-events --stack-name "$lambda_stack" --max-items 5 --query "StackEvents[].ResourceStatusReason"

echo "Lambda Tags"

aws lambda list-tags --resource "$lambda_arn"

echo "Updating lambda stack with new tags (bar=baz)"

aws cloudformation deploy \
    --template-file ./lambda.yml \
    --stack-name "$lambda_stack" \
    --parameter-overrides Prefix="$prefix" \
    --tags bar=baz \
    --role-arn "$cfn_role"

echo "Lambda Tags after update"

aws lambda list-tags --resource "$lambda_arn"

echo "Lambda stack messages:"
aws cloudformation describe-stack-events --stack-name "$lambda_stack" --max-items 5 --query "StackEvents[].ResourceStatusReason"

echo "Cleaning Up Stacks"

if [[ $* == *--dont-cleanup-lambda* ]]; then
  echo "  Skipping Lambda stack cleanup, as requested"
else
  echo "  Deleting $lambda_stack"
  aws cloudformation delete-stack --stack-name "$lambda_stack"
  aws cloudformation wait stack-delete-complete --stack-name "$lambda_stack"
  echo "  Done deleting lambda stack. To skip deleting lambda stack, pass --dont-cleanup-lambda"
fi

if [[ $* == *--cleanup-iam* ]]; then
  echo "  Deleting $role_stack"
  aws cloudformation delete-stack --stack-name "$role_stack"
  aws cloudformation wait stack-delete-complete --stack-name "$role_stack"

else
  echo "  Skipping IAM stack cleanup. Use --cleanup-iam to delete IAM stack"

fi
