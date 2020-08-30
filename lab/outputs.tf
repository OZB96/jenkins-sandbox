output "phi_ip" {
  value = aws_instance.phi.public_ip
}

output "phi" {
  value = format("%s (%s)", aws_instance.phi.public_dns, aws_instance.phi.public_ip)
}

