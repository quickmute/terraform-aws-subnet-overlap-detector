# terraform-aws-subnet-overlap-detector
Terraform code to detect if list of subnets have any overlaps. Pass in a list of Subnets in CIDR notation in Decimal such as `10.10.0.0/24` and it will return a map where the key is the Decimal CIDR and the value is a list of any overlapping CIDRs. 

# Dependency
This module uses the module that converts Decimal CIDR to its long decimal and binary notations. 
https://github.com/quickmute/terraform-aws-subnet-calculator

# Logic
## How to detect overlaps between 2 CIDRs

Given two Subnet (1 and 2) where X is the starting long decimal and Y is the ending long decimal. 
For example, X1 is the Starting of first CIDR and X2 is the Starting of second CIDR. 
So...
if X1 <= X2 AND X2 <= Y1 then it overlaps regardless of Y2
```
ONE     X========================Y
TWO         X========================Y
```
if X1 >= X2 AND X1 <= Y2 then it overlaps regardless of Y1
```
ONE                 X=============Y
TWO         X========================Y
```
All else there is no overlap between 1 and 2 CIDRs

## How to efficiently compare between all CIDRs in a list

Given a 6 item table, full comparision table would like as follows where every x-y coordinate is a compare
```
1 2 3 4 5 6
1 2 3 4 5 6
1 2 3 4 5 6
1 2 3 4 5 6
1 2 3 4 5 6
```
Terraform Code for full pair compare of each items in a list
```
item => [for item2 in local.all_vpc_cidrs : item2]
```

But if we use terraform's `slice` function to use less of the second list during the loop of the first list, then we can cut down the search to following (42% decrease):
```
1 2 3 4 5 6
  2 3 4 5 6
    3 4 5 6
      4 5 6
        5 6
          6
```
Terraform Code for full pair compare of each items in a list
```
item => [for item2 in slice(local.all_vpc_cidrs, index(local.all_vpc_cidrs, item), length(local.all_vpc_cidrs)) : item2
```
