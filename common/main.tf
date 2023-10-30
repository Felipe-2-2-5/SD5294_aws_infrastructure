data "aws_ssm_parameter" "github_token" {
  name            = "${var.project}-${var.environment}-github-token"
  with_decryption = true
}