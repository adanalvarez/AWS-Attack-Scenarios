output "address" {
  value = aws_lb.alb.dns_name
}

output "cognito_hosted_ui_url" {
  value = "https://${aws_cognito_user_pool_domain.app_pool_domain.domain}.auth.${var.region}.amazoncognito.com/login?response_type=token&client_id=${aws_cognito_user_pool_client.app_pool_client.id}&redirect_uri=${var.callbackUrl}"
}

output "cognito_client_id" {
  value       = aws_cognito_user_pool_client.app_pool_client.id
  description = "Cognito User Pool Client ID"
}

output "callback_url" {
  value       = var.callbackUrl
  description = "Callback URL for OAuth2.0"
}

output "cognito_domain" {
  value       = aws_cognito_user_pool_domain.app_pool_domain.domain
  description = "Cognito User Pool domain"
}

output "aws_region" {
  value       = var.region
  description = "AWS region for the resources"
}