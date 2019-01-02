output "nameservers" {
  value = "${aws_route53_zone.zone.name_servers}"
  description = "Nameserver entry for the Domain"

}

output "git_remote_url" {
  value = "${replace(aws_codecommit_repository.git_repository.clone_url_ssh,
    "ssh://",
    "ssh://${aws_iam_user_ssh_key.user.ssh_public_key_id}@")}"
  description = "Remote URL for the Origin Git Repository"
}