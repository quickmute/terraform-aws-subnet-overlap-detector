variable "all_vpc_cidrs"{
  type = list
  description = "A list of Decimal CIDRs"
  default = [
    "10.69.27.0/24",
    "10.69.27.0/28",
    "10.69.28.0/24",
  ]
}

## convert all the Decimal CIDR to it's Long notation
module "converted" {
  ## be sure to put this relative to the other module
  source   = "../terraform-aws-subnet-overlap-detector"
  for_each = { for item in sort(var.all_vpc_cidrs) : item => item }
  cidr     = each.value
}

  
locals {
  find_overlap_slice = {
    for item in var.all_vpc_cidrs :
    item => [for item2 in slice(var.all_vpc_cidrs, index(var.all_vpc_cidrs, item), length(var.all_vpc_cidrs)) : item2
      if((
        ((lookup(module.converted, item).result.host_long_decimal <= lookup(module.converted, item2).result.host_long_decimal) &&
        (lookup(module.converted, item2).result.host_long_decimal <= lookup(module.converted, item).result.bcast_long_decimal)) ||
        ((lookup(module.converted, item).result.host_long_decimal >= lookup(module.converted, item2).result.host_long_decimal) &&
        (lookup(module.converted, item).result.host_long_decimal <= lookup(module.converted, item2).result.bcast_long_decimal))
      ) && item != item2)
    ]
  }

  ## only keep result where there was overlap
  overlap_result = {
    for x, y in local.find_overlap_slice :
    x => y
    if length(y) > 0
  }

}

## The final output shows where there was overlap
output "slice_result" {
  value = local.find_overlap_slice
}
