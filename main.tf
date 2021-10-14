# 创建资源VPC
resource "alicloud_vpc" "vpc" {
  vpc_name   = "xxn_vpc"
  cidr_block = "172.16.0.0/12"
}

# 创建资源switch并指定vpc_id
resource "alicloud_vswitch" "vsw" {
  vpc_id            = alicloud_vpc.vpc.id
  cidr_block        = "172.16.0.0/21"
  zone_id           = "cn-beijing-b"
}

# 负载均衡
resource "alicloud_slb_load_balancer" "slb" {
  load_balancer_name       = "xxn-slb-tf"
  vswitch_id = alicloud_vswitch.vsw.id
}


# 创建资源安全组
resource "alicloud_security_group" "group" {
  name        = "xxn_security_group"
  description = "安全组"
  vpc_id      = alicloud_vpc.vpc.id
}

# resource "alicloud_kms_key" "key" {
#  description            = "Hello KMS"
#  pending_window_in_days = "7"
#  key_state              = "Enabled"
# }

# 创建实例
resource "alicloud_instance" "instance" {

  availability_zone = "cn-hangzhou-b"
  security_groups   = alicloud_security_group.group.*.id

  instance_type              = "ecs.n2.small"
  count                      = var.instance_number 
  system_disk_category       = "cloud_efficiency"
  system_disk_name           = "xxn_system_disk"
  system_disk_description    = "xxn_system_disk_description"
  image_id                   = "ubuntu_18_04_64_20G_alibase_20190624.vhd"
  instance_name              = "xxn_instance"
  vswitch_id                 = alicloud_vswitch.vsw.id
  internet_max_bandwidth_out = 10     #出口带宽
  data_disks {
    name        = "xxn_data_disk"
    size        = 20
    category    = "cloud_efficiency"
    description = "xxn_data_disk"
    encrypted   = true
   # kms_key_id  = alicloud_kms_key.key.id
  }
}

# resource "alicloud_eip_address" "eip" {
# }

# resource "alicloud_eip_association" "eip_asso" {
#   allocation_id = alicloud_eip_address.eip.id
#   instance_id   = alicloud_instance.instance[*].id
# }


module "eip" {
   source = "./modules/eip"
 
   create               = true
   name                 = "ecs-eip"
   description          = "An EIP associated with ECS instance."
   bandwidth            = 1
   internet_charge_type = "PayByTraffic"
   instance_charge_type = "PostPaid"
   period               = 1
   resource_group_id    = ""
   tags = {
     Env      = "Private"
     Location = "foo"
   }
   # The number of instances created by other modules
   number_of_computed_instances = 3
   computed_instances = [
     {
       instance_ids  = alicloud_instance.instance[*].id
       instance_type = "EcsInstance"
       private_ips   = []
     }
   ]
 }


