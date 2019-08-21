# Create a NLB pointing to your k8s masters

Simple terraform file that will create the necessary NLB pointing to an IP Address (to survive updates of the VM).

Create a `terraform.tfvars` file that contains the following:

```
# Referred to in other comments as ${CLUSTER_NAME}
cluster_name = "system"

# pks cluster ${CLUSTER_NAME} --json | jq -c -r .kubernetes_master_ips
kubernetes_master_ips = ["10.0.8.6"]

# Retrieved from AWS console
vpc_id = "vpc-00000000"

# Retrieved from AWS console
public_subnet_ids = ["subnet-000000000", "subnet-000000001"]

# Optional, this will add the necessary tags on the public subnet for load balancers.
# pks cluster system --json | jq -c -r .uuid
cluster_uuid = "000000000000000"

# Optional if using Route 53
# pks cluster ${CLUSTER_NAME} --json | jq -c -r ".parameters.kubernetes_master_host"
cluster_host = "system.pks.dev.example.com"
# Retrieved from AWS console
dns_zone_id = "Z3EXAMPLEEXAMPLE"

# Optional tags
tags = {
  Application = "Cloud Foundry"
  Environment = "dev"
}

```

Then just do this:

```
terraform init
terraform plan -out=pcf.tfplan
terraform apply "pcf.tfplan"
```

You can retrieve most of this information from just the PKS cli, no need to go into bosh or ops manager!