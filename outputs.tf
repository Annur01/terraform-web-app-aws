# Print the public IP so you can visit the server in a browser
output "web_public_ip" {
  description = "Public IP of the web server"
  value       = aws_instance.web.public_ip
}