.DEFAULT_GOAL: help

# User-configurable settings
stack.name := js
stack.region := us-east-1
app.repo := https://github.com/scottbrown/node-restful-api-tutorial

# Try not to modify these settings without understanding their purpose
aws.profile := junglescout-$(ENV)

template.file := template.yml

stack.create.param.1 := ParameterKey=EnvName,ParameterValue=$(ENV)
stack.create.params  := $(stack.create.param.1)

stack.update.param.1 := ParameterKey=EnvName,UsePreviousValue=true
stack.update.params  := $(stack.update.param.1)

stack.tag.1 := Key=repository,Value=$(app.repo)
stack.tag.2 := Key=service,Value=$(stack.name)
stack.tag.3 := Key=env,Value=$(ENV)
stack.tags  := $(stack.tag.1) $(stack.tag.2) $(stack.tag.3)

.PHONY: help
help:  ## Prints this message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: create
create: get-env ## Creates the stack
	aws cloudformation create-stack \
		--stack-name $(stack.name) \
		--region $(stack.region) \
		--profile $(aws.profile) \
		--template-body file://$(template.file) \
		--parameters $(stack.create.params) \
		--enable-termination-protection \
		--tags $(stack.tags)

.PHONY: change
change: get-env ## Creates a changeset 
ifndef NAME
	@echo "Provide a changeset NAME to continue."; exit 1
endif
	aws cloudformation create-change-set \
		--stack-name $(stack.name) \
		--change-set-name $(NAME) \
		--region $(stack.region) \
		--profile $(aws.profile) \
		--template-body file://$(template.file) \
		--parameters $(stack.update.params) \
		--tags $(stack.tags) \
		--capabilities CAPABILITY_IAM

.PHONY: approve
approve: get-env ## Approves the changeset
ifndef NAME
	@echo "Provide a changeset NAME to continue."; exit 1
endif
	aws cloudformation execute-change-set \
		--stack-name $(stack.name) \
		--change-set-name $(NAME) \
		--region $(stack.region) \
		--profile $(aws.profile) \

.PHONY: status
status: get-env ## Displays the last status of the stack
	aws cloudformation describe-stack-events \
		--stack-name $(stack.name) \
		--region $(stack.region) \
		--profile $(aws.profile) \
		--query 'StackEvents[0]'

.PHONY: outputs
outputs: get-env ## Displays the outputs of this stack
	@aws cloudformation describe-stacks \
		--stack-name $(stack.name) \
		--region $(stack.region) \
		--profile $(aws.profile) \
		--query 'Stacks[0].Outputs'

.PHONY: last-create-failure
last-create-failure: get-env ## Displays the last create failure
	aws cloudformation describe-stack-events \
		--stack-name $(stack.name) \
		--region $(stack.region) \
		--profile $(aws.profile) \
		--query 'StackEvents[?ResourceStatus == `CREATE_FAILED`] | [0]'

.PHONY: last-update-failure
last-update-failure: get-env ## Displays the last update failure
	aws cloudformation describe-stack-events \
		--stack-name $(stack.name) \
		--region $(stack.region) \
		--profile $(aws.profile) \
		--query 'StackEvents[?ResourceStatus == `UPDATE_FAILED`] | [0]'

# There is no delete-stack as, in production, we do not want this to be
# automatically/accidentally triggered.  I want someone to jump through
# a manual step to delete the stack.  This can be adjusted as necessary
# as there is additional protection in the form of stack termination
# protection.
.PHONY: delete
delete: get-env ## Deletes the stack
	echo "Not implemented"


# Hidden targets (these are hidden from help, but can still be
# called from the CLI). To make them hidden, do not put a comment
# next to the target name.

.PHONY: get-env
get-env:
ifndef ENV
	@echo "Please provide an ENV to continue."; exit 1
endif
