
output "nodejs_app_public_ip" {
  value = aws_instance.nodejs_app.public_ip
}

output "postgresql_private_ip" {
  value = aws_instance.postgresql.private_ip
} 

output "vpc_id" {
  value = aws_vpc.main.id
} 

output "subnet_public_id" {
  value = aws_subnet.public.id
} 

output "subnet_private_id" {
  value = aws_subnet.private.id
} 

output "app_security_group_id" {
  value = aws_security_group.app_sg.id
} 

output "db_security_group_id" {
  value = aws_security_group.db_sg.id
} 
