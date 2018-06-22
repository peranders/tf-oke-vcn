
##################################################################
# Variable definitions
##################################################################

variable "tenancy_ocid" {}
variable "user_ocid" {}
variable "fingerprint" {}
variable "private_key_path" {}
variable "compartment_ocid" {}
variable "region" {}

data "oci_identity_availability_domains" "ADs" {
  compartment_id = "${var.tenancy_ocid}"
}


variable "vcn_name" {
	default="vcn_oke"
}
variable "vcn_dns_label" {
	default="vcnoke"
}
variable "cidr_vcn" {
	default="10.0.0.0/16"
}

# CIDRs for worker subnets
variable "cidr_subnet_workers_ad1" {
	default="10.0.10.0/24"
}
variable "cidr_subnet_workers_ad2" {
	default="10.0.11.0/24"
}
variable "cidr_subnet_workers_ad3" {
	default="10.0.12.0/24"
}

# CIDRs for Loadbalancers subnets
variable "cidr_subnet_lbrs_ad1" {
	default="10.0.20.0/24"
}
variable "cidr_subnet_lbrs_ad2" {
	default="10.0.21.0/24"
}

# Internet Gateway
variable "ig_name" {
	default="gateway-0"
}

# Route table
variable "rt_display_name" {
	default = "routetable-0"
}

# Subnet workers 
variable "subnet_workers_ad1_name" {
	default="workers_1"
}
variable "subnet_workers_ad2_name" {
	default="workers_2"
}
variable "subnet_workers_ad3_name" {
	default="workers_3"
}
variable "subnet_workers_ad1_dnslabel" {
	default="workers1"
}
variable "subnet_workers_ad2_dnslabel" {
	default="workers2"
}
variable "subnet_workers_ad3_dnslabel" {
	default="workers3"
}

# Subnet Loadbalancers (lbrs)
variable "subnet_lbrs_ad1_name" {
	default="lbrs_1"
}

variable "subnet_lbrs_ad2_name" {
	default="lbrs_2"
}

variable "subnet_lbrs_ad1_dnslabel" {
	default="lbrs1"
}

variable "subnet_lbrs_ad2_dnslabel" {
	default="lbrs2"
}

# Security List names
variable "sl_worker_name" {
	default="sl_workers"
}
variable "sl_lbr_name" {
	default="sl_lbrs"
}


# Security List ICMP options
variable "sl_ingress_icmp_options_type" {
	default="3"
}
variable "sl_ingress_icmp_options_code" {
	default="4"
}

# Security List SSH ingress hosts. 
variable "sl_workers_ingress_ssh_cidr1" {
	default="130.35.0.0/16"
}
variable "sl_workers_ingress_ssh_cidr2" {
	default="138.1.0.0/17"
}

##################################################################
# Provider config
##################################################################
provider "oci" {
  tenancy_ocid = "${var.tenancy_ocid}"
  user_ocid = "${var.user_ocid}"
  fingerprint = "${var.fingerprint}"
  private_key_path = "${var.private_key_path}"
  region = "${var.region}"
}

##################################################################
# Resource definitions
##################################################################
resource "oci_core_virtual_network" "k8s_vcn" {
  cidr_block = "${var.cidr_vcn}"
  dns_label = "${var.vcn_dns_label}"
  compartment_id = "${var.compartment_ocid}"
  display_name = "${var.vcn_name}"
}

resource "oci_core_internet_gateway" "k8s_gateway" {
    compartment_id = "${var.compartment_ocid}"
    display_name = "${var.ig_name}"
    vcn_id = "${oci_core_virtual_network.k8s_vcn.id}"
}

resource "oci_core_route_table" "k8s_routetable" {
    compartment_id = "${var.compartment_ocid}"
    vcn_id = "${oci_core_virtual_network.k8s_vcn.id}"
    display_name = "${var.rt_display_name}"
    route_rules {
        cidr_block = "0.0.0.0/0"
        network_entity_id = "${oci_core_internet_gateway.k8s_gateway.id}"
    }
}

resource "oci_core_security_list" "sl_workers" {
    compartment_id = "${var.compartment_ocid}"
    display_name = "${var.sl_worker_name}"
    vcn_id = "${oci_core_virtual_network.k8s_vcn.id}"
    egress_security_rules = [
		{
			stateless="true"
			protocol="all"
			destination="${var.cidr_subnet_workers_ad1}"
	    },
		{
			stateless="true"
			protocol="all"
			destination="${var.cidr_subnet_workers_ad2}"
	    },
		{
			stateless="true"
			protocol="all"
			destination="${var.cidr_subnet_workers_ad3}"
	    },
		{
			protocol="all"
			destination="0.0.0.0/0"
	    }
	]
    ingress_security_rules = [
		{
			stateless="true"
			protocol="all"
			source = "${var.cidr_subnet_workers_ad1}"
		},
		{
			stateless="true"
			protocol="all"
			source = "${var.cidr_subnet_workers_ad2}"
    	},
		{
			stateless="true"
			protocol="all"
			source = "${var.cidr_subnet_workers_ad3}"
    	},
		{
			protocol = "1"
			source = "0.0.0.0/0"
			icmp_options {
				#Required
				type = "${var.sl_ingress_icmp_options_type}"

				#Optional
				code = "${var.sl_ingress_icmp_options_code}"
			}
    	},
		{
			protocol = "6"
			source = "${var.sl_workers_ingress_ssh_cidr1}"
			tcp_options {
			            "max" = 22
			            "min" = 22
			        }
			
    	},
		{
			protocol = "6"
			source = "${var.sl_workers_ingress_ssh_cidr2}"
			tcp_options {
			            "max" = 22
			            "min" = 22
			        }
			
    	},
		{
			protocol = "6"
			source = "0.0.0.0/0"
			tcp_options {
			            "max" = 22
			            "min" = 22
			        }
			
    	}
		
	]
}

resource "oci_core_security_list" "sl_lbrs" {
    compartment_id = "${var.compartment_ocid}"
    display_name = "${var.sl_lbr_name}"
    vcn_id = "${oci_core_virtual_network.k8s_vcn.id}"
    egress_security_rules = [
		{
			stateless="true"
        	destination = "0.0.0.0/0"
        	protocol = "6"
    	}
	]
    ingress_security_rules = [
		{
			stateless="true"	
			protocol = "6"
			source = "0.0.0.0/0"
  		}
	]
}


resource "oci_core_subnet" "workers_ad1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block = "${var.cidr_subnet_workers_ad1}"
  display_name = "${var.subnet_workers_ad1_name}"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_virtual_network.k8s_vcn.id}"
  dns_label = "${var.subnet_workers_ad1_dnslabel}"
  route_table_id = "${oci_core_route_table.k8s_routetable.id}"
  security_list_ids = ["${oci_core_security_list.sl_workers.id}"]
  dhcp_options_id = "${oci_core_virtual_network.k8s_vcn.default_dhcp_options_id}"
}


resource "oci_core_subnet" "workers_ad2" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  cidr_block = "${var.cidr_subnet_workers_ad2}"
  display_name = "${var.subnet_workers_ad2_name}"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_virtual_network.k8s_vcn.id}"
  dns_label = "${var.subnet_workers_ad2_dnslabel}"
  route_table_id = "${oci_core_route_table.k8s_routetable.id}"
  security_list_ids = ["${oci_core_security_list.sl_workers.id}"]
  dhcp_options_id = "${oci_core_virtual_network.k8s_vcn.default_dhcp_options_id}"
}

resource "oci_core_subnet" "workers_ad3" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[2],"name")}"
  cidr_block = "${var.cidr_subnet_workers_ad3}"
  display_name = "${var.subnet_workers_ad3_name}"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_virtual_network.k8s_vcn.id}"
  dns_label = "${var.subnet_workers_ad3_dnslabel}"
  route_table_id = "${oci_core_route_table.k8s_routetable.id}"
  security_list_ids = ["${oci_core_security_list.sl_workers.id}"]
  dhcp_options_id = "${oci_core_virtual_network.k8s_vcn.default_dhcp_options_id}"
}

resource "oci_core_subnet" "loadbalancers_ad1" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[0],"name")}"
  cidr_block = "${var.cidr_subnet_lbrs_ad1}"
  display_name = "${var.subnet_lbrs_ad1_name}"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_virtual_network.k8s_vcn.id}"
  dns_label = "${var.subnet_lbrs_ad1_dnslabel}"
  route_table_id = "${oci_core_route_table.k8s_routetable.id}"
  security_list_ids = ["${oci_core_security_list.sl_lbrs.id}"]
  dhcp_options_id = "${oci_core_virtual_network.k8s_vcn.default_dhcp_options_id}"
}

resource "oci_core_subnet" "loadbalancers_ad2" {
  availability_domain = "${lookup(data.oci_identity_availability_domains.ADs.availability_domains[1],"name")}"
  cidr_block = "${var.cidr_subnet_lbrs_ad2}"
  display_name = "${var.subnet_lbrs_ad2_name}"
  compartment_id = "${var.compartment_ocid}"
  vcn_id = "${oci_core_virtual_network.k8s_vcn.id}"
  dns_label = "${var.subnet_lbrs_ad2_dnslabel}"
  route_table_id = "${oci_core_route_table.k8s_routetable.id}"
  security_list_ids = ["${oci_core_security_list.sl_lbrs.id}"]
  dhcp_options_id = "${oci_core_virtual_network.k8s_vcn.default_dhcp_options_id}"
}

