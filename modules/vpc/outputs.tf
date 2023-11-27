output "vpc" {
  value = aws_default_vpc.default
}

output "default-public" {
  value = aws_default_subnet.default-public
}

output "default-private-1" {
  value = aws_default_subnet.default-private-1
}

output "default-private-2" {
  value = aws_default_subnet.default-private-2
}