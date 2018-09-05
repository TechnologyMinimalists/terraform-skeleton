#!/bin/bash

set -u
set -e
#set -x

# Set default workdir and action variables
WORKDIR="$( pwd )"
ACTION="plan"
DRY_RUN=true
RETCODE=0
ACCOUNT=""
ENVIRONMENT=""
ZONE=""

# Show usage
function show_usage() {
    echo "$0 -a ACCOUNT_NAME -e ENVIRONMENT -z ZONE [-X] [-?|-h]"
    echo ""
    echo -e "\t-a \t- Account name - one of acounts inside accounts directory, eg. main.tld"
    echo -e "\t-e \t- Workspace (environment) name, eg. production, development, staging"
    echo -e "\t-z \t- AWS zone, eg. eu-west-1, eu-cental-1, it might be also a custom name, eg. global"
    echo -e "\t-X \t- Run 'terraform apply' after 'terraform plan' suceeds (POSSIBLY DANGEROUS)"
    echo -e "\t-h \t- Usage"
}

function set_terraform_vars() {
    local tfvars="region = \"$ZONE\"
environment = \"$ENVIRONMENT\"
account = \"$ACCOUNT\"
"
    echo "$tfvars" > ./terraform.tfvars
}

# Check if Terraform binary is in PATH
if command -v terraform &> /dev/null; then
  TERRAFORM_BIN="$(command -v terraform)"
else
  echo "Terraform not installed?"
  exit 1
fi

## Options parsing
while getopts ":a:e:z:Xh" opt; do
    case $opt in
        a)
            ACCOUNT="$OPTARG"
            ;;
        e)
            ENVIRONMENT="$OPTARG"
            ;;
        z)
            ZONE="$OPTARG"
            export AWS_DEFAULT_REGION="$OPTARG"
            ;;
        h)
            show_usage
            exit 0
            ;;
        X)
            DRY_RUN=false
            ;;
        \?)
            show_usage
            echo "ERROR: Invalid option: -$OPTARG"
            exit 1
            ;;
        :)
            show_usage
            echo "ERROR: Option -$OPTARG requires an argument."
            exit 1
            ;;
    esac
done

# Make sure all needed options are set
if [ -z "$ACCOUNT" ] || [ -z "$ENVIRONMENT" ] || [ -z "$ZONE" ]; then
    echo "ERROR: All options must be set."
    exit 1
fi

# Check if environment exist
if [ ! -d "accounts/${ACCOUNT}/${ZONE}" ]; then
    echo "ERROR: Environment '${ACCOUNT}/${ZONE}' not found"
    exit 1
fi

# Go to correct environment
cd "accounts/${ACCOUNT}/${ZONE}"

set_terraform_vars

# Init terraform backend
$TERRAFORM_BIN init -input=false

# Set workspace (new) - workspaces MUST be defined and present in git
if ! `$TERRAFORM_BIN workspace select $ENVIRONMENT >/dev/null 2>&1`; then
  $TERRAFORM_BIN workspace new $ENVIRONMENT 
fi

# Get Terraform modules
$TERRAFORM_BIN get

# Basic tests
# Run TF validity
echo " => Validating Terraform manifest..."
$TERRAFORM_BIN validate
echo " done."

# Run syntax checks
echo "=> Validating syntax"
$TERRAFORM_BIN fmt -check=true
echo "done"

# Plan changes
echo "Running plan..."
$TERRAFORM_BIN plan -input=false -out=./terraform.tfplan

if [ "$DRY_RUN" = false ]; then
    echo "Sleeping for 30 seconds before apply..."
    sleep 30

    echo "Running Terraform now"
    # Run apply, we may need to run it several times in the future
    if $TERRAFORM_BIN apply -input=false ./terraform.tfplan; then
        echo "Terraform finished successfully"
        RETCODE=0
    else
        # We will support retries later
        echo "Failed! No retries configured"
        RETCODE=1
    fi
fi

echo "All done!"
cd $WORKDIR
exit $RETCODE
