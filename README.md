[terraform]: https://terraform.io
[oci]: https://cloud.oracle.com/cloud-infrastructure
[oci provider]: https://github.com/oracle/terraform-provider-oci/releases
[API signing]: https://docs.us-phoenix-1.oraclecloud.com/Content/API/Concepts/apisigningkey.htm
[Kubectl]: https://kubernetes.io/docs/tasks/tools/install-kubectl/

[oke]: https://docs.cloud.oracle.com/iaas/Content/ContEng/Concepts/contengoverview.htm
[oke_vcn]: https://docs.cloud.oracle.com/iaas/Content/ContEng/Concepts/contengnetworkconfig.htm
[oke_vcn_sample]: https://docs.cloud.oracle.com/iaas/Content/ContEng/Concepts/contengnetworkconfigexample.htm
[oci_keys_and_ocid]: https://docs.cloud.oracle.com/iaas/Content/API/Concepts/apisigningkey.htm



# Terraform Installer for Network configuration required by Oracle Container Engine for Kubernetes (OKE)
## About

Oracle Cloud Infrastructure Container Engine for Kubernetes is a fully-managed, scalable, and highly available service that you can use to deploy your containerized applications to the cloud (sometimes abbreviated to just [OKE][oke]).  

OKE lets you spin up a new Kubernetes cluster in a couple of minutes, but before you do that you need to create a network configuration to host your worker nodes. This terraform installer takes care of the network configuration required by OKE to host your Kubernetes worker nodes and Loadbalancers on [Oracle Cloud Infrastructure][oci] (OCI). This network configuration is in accordance with the sample network configuration provided by the OKE documentation. 



## Network Overview

Terraform is used to _provision_ the virtual cloud network and all required resources for OKE. According to the documentation the [OKE network][oke_vcn] has the following requirements:

- The VCN must have a CIDR block defined that is large enough for at least five subnets, in order to support the number of hosts and load balancers a cluster will have. A /16 CIDR block would be large enough for almost all use cases (10.0.0.0/16 for example). The CIDR block you specify for the VCN must not overlap with the CIDR block you specify for pods and for the Kubernetes services.
- The VCN must have an internet gateway defined.
- The VCN must have a route table defined that has a route rule specifying the internet gateway as the target for the destination CIDR block.
- The VCN must have five subnets defined. 
- The VCN must have security lists defined for the worker node subnets and the load balancer subnets. 

The OKE documentation also refers to a [oke_vcn_sample][network config with sample values], and this provider are using the values from this example, but you can change it using your own names and values.



![](./images/oke_network.jpg)

## Prerequisites

1. Download and install [Terraform][terraform] (v0.10.3 or later)
2. Download and install the [OCI Terraform Provider][oci provider] (v2.0.0 or later)
3. Create an Terraform configuration file at  `~/.terraformrc` that specifies the path to the OCI provider:
```
providers {
  oci = "<path_to_provider_binary>/terraform-provider-oci"
}
```



## Quick start

### Customize the configuration

The configuration is separated in two files. One for Mandatory Input variables and another one for optional variables further details described below.


#### Mandatory Input Variables:
The first section in the terraform.tfvars file contains the mandatory variables you need to connecto to you oci instance.  Uncomment the lines and replace the values with your specific settings. Check the documentation for [Required Keys and OCID][oci_keys_and_ocid] for how to obtain the necessary values.

name                                | default                 | description
------------------------------------|-------------------------|-----------------
tenancy_ocid                        | None (required)         | Tenancy's OCI OCID
compartment_ocid                    | None (required)         | Compartment's OCI OCID
user_ocid                           | None (required)         | Users's OCI OCID
fingerprint                         | None (required)         | Fingerprint of the OCI user's public key
private_key_path                    | None (required)         | Private key file path of the OCI user's private key
region                              | None (required)         | String value of region to create resources

Another option is to create your own script like _setocienv.sh_ to set the necessary terraform environment varaibles:
```
export TF_VAR_tenancy_ocid="<Replace with your oci tenancy OCID>"
export TF_VAR_user_ocid="<Replace with your oci user OCID>"
export TF_VAR_fingerprint="<Replace with your pem public key fingerprint>"
export TF_VAR_private_key_path="<Replace with Path to your pem private key>"
export TF_VAR_compartment_ocid="<Replace with your oci compartment OCID>"
export TF_VAR_region="<Replace with your region name, e.g: eu-frankfurt-1>"
```	

#### Optional Input Variables:
The configuration has a lot of default values that you can customize. Open terraform.tfvars and comment out any lines with values you would like to chabnge.  
If no values are changed you will configure your network according to the values shown in the figure above. 

##### VCN parameters 
name                                | default                 | description
------------------------------------|-------------------------|------------
vcn_name                            | vcn_oke                 | Name of the VCN network
vcn_dns_label                       | vcnoke                  | Dns name of the VCN network
cidr_vcn                            | 10.0.0.0/16             | CIDR of the VCN network

##### Worker subnets 
name                                | default                 | description
------------------------------------|-------------------------|------------
subnet_workers_ad1_name             | workers_1               | Name of the workers subnet in ad1
subnet_workers_ad2_name             | workers_2               | Name of the workers subnet in ad2
subnet_workers_ad3_name             | workers_3               | Name of the workers subnet in ad3
subnet_workers_ad1_dnslabel         | workers1                | Dns name of the workers subnet in ad1
subnet_workers_ad2_dnslabel         | workers2                | Dns name of the workers subnet in ad2
subnet_workers_ad3_dnslabel         | workers3                | Dns name of the workers subnet in ad3
cidr_subnet_workers_ad1             | 10.0.10.0/24            | CIDR for workers subnet in ad1
cidr_subnet_workers_ad2             | 10.0.11.0/24            | CIDR for workers subnet in ad2
cidr_subnet_workers_ad3             | 10.0.12.0/24            | CIDR for workers subnet in ad3

##### Loadbalancer subnets 
name                                | default                 | description
------------------------------------|-------------------------|------------
subnet_lbrs_ad1_name                | lbrs_1                  | Name of the lbr subnet in ad1
subnet_lbrs_ad2_name                | lbrs_2                  | Name of the lbr subnet in ad2
subnet_lbrs_ad1_dnslabel            | lbrs1                   | Dns name of the lbr subnet in ad1
subnet_lbrs_ad2_dnslabel            | lbrs2                   | Dns name of the lbr subnet in ad2
cidr_subnet_lbrs_ad1                | 10.0.20.0/24            | CIDR for lbr subnet in ad1
cidr_subnet_lbrs_ad2                | 10.0.21.0/24            | CIDR for lbr subnet in ad2

##### Internet Gateway                                          
name                                | default                 | CIDR for workers subnet in ad3description
------------------------------------|-------------------------|------------
ig_name                             | gateway-0               | Name of the Internet gateway

##### Routetable
name                                | default                 | description
------------------------------------|-------------------------|------------
rt_display_name                     | routeable-0             | Name of the routetable

##### Security Lists
name                                | default                 | description
------------------------------------|-------------------------|------------
sl_worker_name                      |                         | Name of the worker security list
sl_lbr_name                         |                         | Name of the lbr security list



### Deploy the network

Run the following terraform commands from the directory containing the terraform files.  

Initialize Terraform:

```
$ terraform init
``` 

View what Terraform plans do before actually doing it:

```
$ terraform plan
```

Use Terraform to Provision k8s network resources on OCI:

```
$ terraform apply
```


