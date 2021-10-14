# output "eip" {
#  value = alicloud_eip_address.eip.public_ip
# }


output "slb"{
  value = alicloud_slb_load_balancer.slb.address
}
