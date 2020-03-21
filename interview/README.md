# Tech Challenge

## Instructions

Please create a GitHub repo with demonstrates your technical skills:

[x] Can you containerize(Docker or Kubernetes) this simple app (https://github.com/academind/node-restful-api-tutorial) or create your own app.
[x] Provision the application onto one of the following: AWS ECS, AWS EKS, AWS EB using infrastructure as code (Terraform, Cloudformation).
[x] Describe how you would monitor this application e.g metrics you would track and thresholds you would report on.
[x] Describe how you would protect this app from being accessed by unauthorized users.
[x] Describe how would you set up the env so it scales automatically when response time drops below 20ms.

Feel free to add:

[x] README files
[x] Tests
[x] Diagrams
[x] Code/Configs
[x] Screenshots of a working version
[x] Examples of how you would provision using infrastructure as code.
[ ] Optionally a CI configuration
[x] And anything that you feel comfortable to show your skills

Note: If you have any extra costs associated with AWS with this code challenge, please send us the invoice for reimbursement. The charges will need to be pre-approved.

## Answers

# Describe how you would monitor this application e.g metrics you would track and thresholds you would report on.

I would track memory and CPU usage, then scale up or down the service as needed.  ECS can have autoscaling provisioned for the cluster and will react to Cloudwatch alarms on specific dimensions, like CPU or memory thresholds.

I would also add a Route53 healthcheck on the URL endpoint and attach it to a cloudwatch alarm.  If the alarm fires, I would have it page out (PageDuty, etc) and get someone on it immediately.  If the problem is happening often, then we need to look at what is causing the repeated issue.

I have built in multi-AZ load balancing and, optionally, multi-AZ application service so we would not experience a single AZ outage.  However, an underlying service, like IAM, could knock out the entire application so we would need to be cognizant of that situation (it happens more than you think).

# Describe how you would protect this app from being accessed by unauthorized users.

What kind of unauthorized users?  Is this API expected to be limited to a specific IP address, or a given API key, or for only internal users?

A specific IP address won't work because JungleScout is a remote-friendly company, and people work from various IP addresses.  Otherwise, we could put a WAF in front of it to block anyone but a specific set of IP addresses.

For API keys, put a CloudFront distribution in front of it and then attach a Lambda@Edge function to it, requiring either an HTTP Basic check or an API Key lookup from a DynamoDB table.  Then restrict the ingress on the application servers to only those IP addresses coming from AWS IPs.  But, I'm not sure how this would work with CloudFront, because each edge node (PoP) might call back to the origin and we don't know the IP addresses of each edge node.

I also wonder if we could put an ALB target group with Cognito authentication onto it, then forward requests over to the application on success.  I've never done this but some Amazon docs exist to show how this is done with ALB and CloudFront.

Since the service may be transmitting sensitive information, it would need an SSL/TLS encryption, so I would front it with CloudFront so that it can hold the ACM certificate.

On the network level, the security groups block nosey users from scanning the ECS host because I am locking down all ingress to just requests from the load balancer.  The load balancers themselves allow the Internet to scan them on port 80 (HTTP), but even attacking these nodes wouldn't result in any security breach because the LBs are isolated from the application (ECS) instances via subnets.

# Describe how would you set up the env so it scales automatically when response time drops below 20ms.

I don't see a CloudWatch metric for this.  That said, there is a new (Sep 2019) feature called Container Insights that might provide this metric.  If it is a metric that can be published to Cloudwatch, then a CloudWatch alarm can be generated and we can modify the scaling policy to help with that.  However, it depends on why the application response time is dropping.

Is the response time dropping due to slow database?  What about other external (to AWS) network calls?  We would need to investigate what is causing the issue before we can make a change like increasing autoscaling, as this could have knock-on effects like exhausting database connection pools.  That said, we would need to look at scaling the database layer based on its metrics, cache layer, or the ECS application layer.  We would also need to know what the steady-state is for the application, because we could be experiencing a DDoS so instead of autoscaling (and losing money) we could deploy a WAF in front of the ALB/CloudFront instance and block the offending IP addresses, negating the use of autoscaling and restoring response times for customers.

## README Files

This is the readme file to read.

Also, because a Makefile is used, you can run `make` and a help is displayed to you.  Here is the output:

```bash
$ make
approve                        Approves the changeset
change                         Creates a changeset 
create                         Creates the stack
delete                         Deletes the stack
help                           Prints this message
last-create-failure            Displays the last create failure
last-update-failure            Displays the last update failure
outputs                        Displays the outputs of this stack
status                         Displays the last status of the stack
test                           Tests the deploy stack from the web
```

## Tests

The only tests I came up with is:

1. Create the stack and ensure that it gets created successfully.
1. Run `make test ENV=...` to hit the service endpoint and get the result.

## Architecture Diagram

![Architecture Diagram](./interview/architecture.png)

## Screenshots

Local working copy:

![Local Environment Screenshot](./interview/screenshot-local.png)

ECS working copy:

![ECS Screenshot](./interview/screenshot-ecs.png)

The ECS environment is available [here](http://js-LoadBala-1IA9AQ3IW4BAY-1407467690.us-east-1.elb.amazonaws.com).  This can also be found after launching the CloudFormation stack successfully:

```bash
$ make outputs ENV=dev
[
    {
        "Description": "URL endpoint for the service (non-SSL)", 
        "OutputKey": "ServiceUrl", 
        "OutputValue": "http://js-LoadBala-1IA9AQ3IW4BAY-1407467690.us-east-1.elb.amazonaws.com"
    }
]

```

## Provisioning

This project's infrastructure uses `make` to provision and maintain the
AWS infrastructure.  To create the stack the first time:

```bash
$ make create ENV=...
```

Then when updating the stack, we use CloudFormation change sets to
prevent accidental replacements and to add a review/approve step:

```bash
$ make change ENV=... NAME=...
..review the change ...
$ make approve ENV=... NAME=...
```

When building the CloudFormation stack initially, it is easier to
iterate on the stack piece-by-piece rather than throw a bunch of
resource creation requests at CloudFormation, each of which could fail.
So this method is something that I've found a lot of success in when
embarking on a new type of service I've never used (in this case, ECS).

## And anything that you feel comfortable to show your skills

* I specifically don't provide names for CloudFormation (CFN) resources, because otherwise then any updates to the names would require replacement of those resources.  In addition, it could cause name conflicts when deploying the same service to the same region where one already exists.  Instead, using randomly-generated names from AWS ensures consistent naming and no conflicts.
* I included the VPC and Subnet resources in the CloudFormation stack because I prefer to isolate the application from all other applications unless it needs to live with other applications.  I specifically do not promote the use of the default VPC as it is an anti-pattern.
* I had to recreate the networking layer because in my AWS accounts I have already removed the default VPC so I can't use it even if I wanted.  This increased the amount of time to complete the project.
* I created 2 subnets for load balancers for multi-AZ failover support and to separate the LBs from the ECS service in the event of IP address exhaustion.  I would also harden the ECS subnet so that there is no public ingress, but I ran short of time.
* I try to use the default values in CloudFormation resources to reduce the size of the template (there are hard limits by AWS) and increase readability.  If something needs to be changed, we update the template, then update the stack.
* The provisioning is intended to be as independent as possible so that it doesn't rely on external services or tools.  This can be adjusted later, but I find that changing/updating CFN stacks can show there is a probllem in automation, so I prefer to nudge people to create stacks once and update as necessary, but only when it is absolutely required.
* Many of the CFN parameters have defaults not because they are expected to be user-configurable, but to reduce magic constants in the template.
* I omitted some hardening steps that I would usually do, like enabling Flow Logs on the VPC/subnet.  This was done for time and readability of the project.
* I probably would break this up into 2 stacks, one for networking and the other for application.  But for expediency and for ease of cleanup, I put them all into one stack.
* I'd love to use slim or scratch to build the docker image since it is quite large and could impact CI runtimes (during push), costs (for storage in ECR) or startup times on ECS.
* Depending on the security need, I would pin the base image used in the docker container to the hash instead of a tag because Docker tags can be overwritten and you might now realize what you are getting.
* I didn't include SSL termination for the load balancer.  I would have had to create a DNS record and an ACM certificate, but I was not going to attach it to a domain I have.
* The resulting docker image uses a `.dockerignore` file to prevent the accidental inclusion of the `.git` directory and other non-application related code.  This is especially useful when the Docker image is made availble through DockerHub.

## Bugs I found

* ECR has changed their login process from the AWS CLI.  Their documentation references something that no longer exists in the CLI.
* Using IAM role paths seems to break the role assumption used by the ECS task scheduler.  I commented them out and the ECS service started working.
* ECS requires the use of `AssignPublicIP: ENABLED` in order to pull docker images from anywhere.  This was not in the CFN docs, but rather in the support docs when you Google the error code produced by ECS.
