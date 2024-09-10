output "vpc_id" {
  description = "The ID of the VPC"
  value       = aws_vpc.sec-vpc.id
}

# Output Load Balancer ARN
output "gwlb_arn" {
  value = aws_lb.GWLBep-security-lb.arn
}

# Output Load Balancer ARN
output "gwlb_endpoint_service" {
   value = aws_vpc_endpoint_service.sec-gwlb_endpoint_service.service_name
}

# Output Transit Gateway ID
 output "transit_gateway_id" {
  value = aws_ec2_transit_gateway.sec-tgw.id
}

# # Output service name
#  output "service_name" {
#   value = aws_vpc_endpoint_service.sec-gwlb_endpoint_service.service_name
# }


