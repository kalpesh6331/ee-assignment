output "jenkinsURL" {
  value = "http://${aws_instance.ee_public_instance.public_dns}:8080"
}

output "publicInstanceIP" {
  value = "${aws_instance.ee_public_instance.public_ip}"
}

output "privateInstanceIP" {
  value = "${aws_instance.ee_private_instance.private_ip}"
}