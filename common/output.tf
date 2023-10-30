output "github_token" {
  value     = data.aws_ssm_parameter.github_token.value
  sensitive = true
}