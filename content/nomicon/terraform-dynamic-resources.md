+++
title = "Dynamic Resource Blocks"
description = "Look, it's HCL, ok?"
date = 1970-01-01
[taxonomies]
categories = [ "Technical" ]
tags = [ "nomicon", "terraform", "hcl" ]
+++

# Dynamic resources

## Chained dynamic resources

In this example our security groups are the primary dynamic resource.
Secondary to that is security group rules, one per dynamic security group.

```hcl
locals {
  ip_list = [ "0.0.0.0", "127.0.0.1" ]
}

data "aws_vpcs" "all_vpcs" {}

resource "aws_security_group" "one_per_each_vpc_in_the_region" {
  for_each = toset(data.aws_vpcs.all_vpcs.ids)
  name = "VeryCommonGroup"
  description = "Some kind of common networking/security access that should be available to every service"
  vpc_id = each.key
}

resource "aws_security_group_rule" "dynamic_rules_for_each_group" {
  for_each = aws_security_group.one_per_each_vpc_in_the_region
  cidr_blocks = formatlist("%s/32", local.ip_list)
  protocol = "all"
  security_group_id = each.value.id
  type = "ingress"
  from_port = -1
  to_port = -1
}

```

## Data-driven dynamic resources

Sometimes you have a complex mapping that's best represented as data.
Here we have such an example binding PermissionSets, Groups, and Accounts.

We map a static value (name) to avoid complications about derived values
`The “for_each” map cannot be determined keys`
When working with unknown values in for_each, it's better to define the map keys statically in your configuration.
That way you can place apply-time results only in the map values.
`uuid()` is also dynamic, so didn't resolve the issue.

```hcl
locals {
  access_bindings = [
    { name : "any_value", permissionset_arn : "arn:aws:sso:::permissionSet/anything", group_id : "1234", account_id : "1234" }
    { name : "some_value", permissionset_arn : "arn:aws:sso:::permissionSet/something", group_id : "4321", account_id : "4321" }
  ]
}

resource "aws_ssoadmin_account_assignment" "account_binding" {
  for_each           = { for r in local.access_bindings : r.name => r }
  instance_arn       = tolist(data.aws_ssoadmin_instances.azure_ad.arns)[0]
  permission_set_arn = each.value["permissionset_arn"]
  principal_id       = each.value["group_id"]
  target_id          = each.value["account_id"]

  principal_type = "GROUP"
  target_type    = "AWS_ACCOUNT"
}

```
