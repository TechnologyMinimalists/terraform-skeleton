#!/bin/bash

set -u
set -e
# set -x

# Set default bucket
BUCKET_NAME=""
BUCKET_REGION=""

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
    echo -e "\t-e \t- Environment name, eg. prod, dev, int"
    echo -e "\t-z \t- AWS zone, eg. eu-west-1, eu-cental-1, it might be also a custom name"
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
if [ ! -d "accounts/${ACCOUNT}/${ENVIRONMENT}/${ZONE}" ]; then
    echo "ERROR: Environment '${ACCOUNT}/${ENVIRONMENT}/${ZONE}' not found"
    exit 1
fi

# Go to correct environment
cd "accounts/${ACCOUNT}/${ENVIRONMENT}/${ZONE}"

set_terraform_vars

$TERRAFORM_BIN init -input=false

# Get Terraform modules
$TERRAFORM_BIN get

# Plan changes
echo "Running plan..."
$TERRAFORM_BIN plan

if [ "$DRY_RUN" = false ]; then
    echo "Sleeping for 30 seconds before apply..."
    sleep 30

    echo "Running Terraform now"
    # Run apply, we may need to run it several times in the future
    if $TERRAFORM_BIN apply; then
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

