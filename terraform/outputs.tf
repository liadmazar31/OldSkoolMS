output "instance_id" {
  description = "ID of the EC2 instance"
  value       = aws_instance.cosmic_server.id
}

output "instance_public_ip" {
  description = "Public IP address of the EC2 instance"
  value       = aws_eip.cosmic_eip.public_ip
}

output "instance_public_dns" {
  description = "Public DNS name of the EC2 instance"
  value       = aws_instance.cosmic_server.public_dns
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = aws_vpc.cosmic_vpc.id
}

output "security_group_id" {
  description = "ID of the security group"
  value       = aws_security_group.cosmic_sg.id
}

output "ssh_command" {
  description = "SSH command to connect to the instance"
  value       = "ssh -i ~/.ssh/${var.key_name}.pem ec2-user@${aws_eip.cosmic_eip.public_ip}"
}

output "maplestory_connection_info" {
  description = "MapleStory server connection information"
  value = {
    login_server = "${aws_eip.cosmic_eip.public_ip}:8484"
    channels     = "Ports 7575-7577"
    public_ip    = aws_eip.cosmic_eip.public_ip
  }
}
