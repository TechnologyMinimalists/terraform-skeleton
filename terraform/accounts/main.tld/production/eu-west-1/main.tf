# Configure the AWS Provider
provider "aws" {
    region = "${var.region}"
}

module "some_example_module_main_vpc" {
    source = "../../../../modules/aws-vpc"

    name = "Some VPC"

    region = "${var.region}"
    map_public_ip_on_launch = false
}

