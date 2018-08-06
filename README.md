# Terraform

Install Terraform downloaded from [this website](https://terraform.io)

Place it in your `$PATH` variable for ease of use. You might also like [this Makefile](https://github.com/gstlt/dotfiles/tree/master/hashicorp) which will install also Packer if you want it to.

You will need API keys to AWS to be able to use it. MFA + AssumeRole is not covered here.

To use the variables without passing it or typing every time you need to run Terraform:
```
export TF_VAR_aws_access_key=ACCESSKEY
export TF_VAR_aws_secret_key=SECRETKEYWHICHISVERYLONGSTRING
```

Or, you can also use `AWS_PROFILE`:
```
AWS_PROFILE=someprofile
```

## Download Terraform (and Packer)

```
make terraform
```

Edit `Makefile` to update Terraform version

## Validating template:
```
terraform verify
```

## Testing

Check what would Terraform do if ran right now:
```
terraform plan
```

To check what would be removed if you want to destroy infrastructure:
```
terraform plan -destroy
```

IMPORTANT: Have in mind that by default terraform state file is being saved locally only.

## Running Terraform on a particular account, environment and zone

```
cd terraform/accounts/int/eu-central-1/
terraform plan
```

