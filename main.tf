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
  load_balancer_spec       = "slb.s2.small"
}

resource "alicloud_slb_listener" "default" {
  load_balancer_id          = alicloud_slb_load_balancer.slb.id
  backend_port              = 80
  frontend_port             = 80
  protocol                  = "http"
  bandwidth                 = 10
  sticky_session            = "on"
  sticky_session_type       = "insert"
  cookie_timeout            = 86400
  cookie                    = "testslblistenercookie"
  health_check              = "on"
  health_check_domain       = "ali.com"
  health_check_uri          = "/cons"
  health_check_connect_port = 20
  healthy_threshold         = 8
  unhealthy_threshold       = 8
  health_check_timeout      = 8
  health_check_interval     = 5
  health_check_http_code    = "http_2xx,http_3xx"
  x_forwarded_for {
    retrive_slb_ip = true
    retrive_slb_id = true
  }
  acl_status      = "on"
  acl_type        = "white"
  acl_id          = alicloud_slb_acl.default.id
  request_timeout = 80
  idle_timeout    = 30
}

resource "alicloud_slb_acl" "default" {
  name       = "xxn_slb_acl"
  entry_list {
    entry   = "10.10.10.0/24"
    comment = "first"
  }
  entry_list {
    entry   = "168.10.10.0/24"
    comment = "second"
  }
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

  availability_zone = "cn-beijing-b"
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
    encrypted   = false
   # kms_key_id  = alicloud_kms_key.key.id
  }
}

resource "alicloud_slb_server_group" "default" {
  load_balancer_id = alicloud_slb_load_balancer.slb.id
  name             = "xxn_alicloud_slb_server_group"
  servers {
    server_ids = alicloud_instance.instance.*.id
    port       = 100
    weight     = 10
  }
  servers {
    server_ids = alicloud_instance.instance.*.id
    port       = 80
    weight     = 100
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
   number_of_computed_instances = 1
   computed_instances = [
     {
#        instance_ids  = alicloud_instance.instance[*].id
       instance_ids  = alicloud_slb_load_balancer.slb.id
       instance_type = "EcsInstance"
       private_ips   = []
     }
   ]
 }


