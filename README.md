# Cloudformation-Lambda Permissions PoC

This illustrates an issue with Lambda permissions. 

To see the issue, run `./run-test.sh my-test-prefix`.  This will create the necessary stacks and show the result.

First, it creates an IAM stack with the necessary permissions.
Then, it creates a stack with a lambda, with the tag foo=bar

We then output the lambda's tags and any messages from the stack creation

Then, we update the stack with a new tag, bar=baz

Watch as Cloudformation outputs warnings and doesn't update the tags!

Then, we cleanup the stacks. If you want to manually inspect the lambda stack, pass  the '--dont-cleanup-lambda' flag.

We keep the IAM stack around (since it takes some time to create). To delete it, pass the '--cleanup-iam' flag.

The created role is assumable by the OIT AccountAdministrator role for testing


