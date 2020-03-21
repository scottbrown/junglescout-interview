# Tech Challenge

## Instructions

Please create a GitHub repo with demonstrates your technical skills:

1. Can you containerize(Docker or Kubernetes) this simple app (https://github.com/academind/node-restful-api-tutorial) or create your own app.
1. Provision the application onto one of the following: AWS ECS, AWS EKS, AWS EB using infrastructure as code (Terraform, Cloudformation).
1. Describe how you would monitor this application e.g metrics you would track and thresholds you would report on.
1. Describe how you would protect this app from being accessed by unauthorized users.
1. Describe how would you set up the env so it scales automatically when response time drops below 20ms.

Feel free to add:

[ ] README files
[ ] Tests
[ ] Diagrams
[ ] Code/Configs
[ ] Screenshots of a working version
[ ] Examples of how you would provision using infrastructure as code.
[ ] Optionally a CI configuration
[ ] And anything that you feel comfortable to show your skills

Note: If you have any extra costs associated with AWS with this code challenge, please send us the invoice for reimbursement. The charges will need to be pre-approved.

## Answers

# Describe how you would monitor this application e.g metrics you would track and thresholds you would report on.

# Describe how you would protect this app from being accessed by unauthorized users.

What kind of unauthorized users?  Is this API expected to be limited to a specific IP address, or a given API key, or for only internal users?

A specific IP address won't work because JungleScout is a remote-friendly company, and people work from various IP addresses.  Otherwise, we could put a WAF in front of it to block anyone but a specific set of IP addresses.

For API keys, put a CloudFront distribution in front of it and then attach a Lambda@Edge function to it, requiring either an HTTP Basic check or an API Key lookup from a DynamoDB table.  Then restrict the ingress on the application servers to only those IP addresses coming from AWS IPs.  But, I'm not sure how this would work with CloudFront, because each edge node (PoP) might call back to the origin and we don't know the IP addresses of each edge node.

We could put an ELB in front and restrict based on IP address.  Or make a software change to lookup API keys.

Since the service may be transmitting sensitive information, it would need an SSL/TLS encryption, so I would front it with CloudFront so that it can hold the ACM certificate.

# Describe how would you set up the env so it scales automatically when response time drops below 20ms.

## Architecture Diagram

![Architecture Diagram](./interview/architecture.png)

## Screenshots

Local working copy:

![Local Environment Screenshot](./interview/screenshot-local.png)

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
* I included the VPC and Subnet resources in the CloudFormation stack because I prefer to isolate the application from all other applications unless it needs to live with other applications.  I specifically do not promote the use of the default VPC as it is an anti-pattern -- in my AWS accounts I have already removed the default VPC so I can't use it even if I wanted.
* I try to use the default values in CloudFormation resources to reduce the size of the template (there are hard limits by AWS) and increase readability.  If something needs to be changed, we update the template, then update the stack.
* The provisioning is intended to be as independent as possible so that it doesn't rely on external services or tools.  This can be adjusted later, but I find that changing/updating CFN stacks can show there is a probllem in automation, so I prefer to nudge people to create stacks once and update as necessary, but only when it is absolutely required.
* Many of the CFN parameters have defaults not because they are expected to be user-configurable, but to reduce magic constants in the template.
* I omitted some hardening steps that I would usually do, like enabling Flow Logs on the VPC/subnet.  This was done for time and readability of the project.
* I probably would break this up into 2 stacks, one for networking and the other for application.  But for expediency and for ease of cleanup, I put them all into one stack.
* I'd love to use slim or scratch to build the docker image since it is quite large and could impact CI runtimes (during push), costs (for storage in ECR) or startup times on ECS.
* Depending on the security need, I would pin the base image used in the docker container to the hash instead of a tag because Docker tags can be overwritten and you might now realize what you are getting.

## Bugs I found

* ECR has changed their login process from the AWS CLI.  Their documentation references something that no longer exists in the CLI.
* Using IAM role paths seems to break the role assumption used by the ECS task scheduler.  I commented them out and the ECS service started working.
