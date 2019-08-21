# Create a NLB pointing to your k8s masters

Simple terraform file that will create the necessary NLB pointing to an IP Address (to survive updates of the VM).

```
cluster_name = "system"

# pks cluster system --json | jq -c -r .kubernetes_master_ips
ip_address = ["10.0.8.6"]

vpc_id = "vpc-00000000"

tags = {
  Application = "Cloud Foundry"
  Environment = "dev"
}

public_subnet_ids = ["subnet-000000000", "subnet-000000001"]

# Optional if using Route 53
# pks cluster ${CLUSTER_NAME} --json | jq -c -r ".parameters.kubernetes_master_host"
cluster_host = "system.pks.dev.example.com"
dns_zone_id = "Z3EXAMPLEEXAMPLE"

```

You can retrieve most of this information from just the PKS cli, no need to go into bosh or ops manager!