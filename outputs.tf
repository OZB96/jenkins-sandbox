output "phi" {
  value = module.dev.phi
}

output "phi_ip" {
  value = module.dev.phi_ip
}

output "private_key" {
  value = file(var.private_key_path)
}

output "public_key" {
  value = file(var.public_key_path)
}
