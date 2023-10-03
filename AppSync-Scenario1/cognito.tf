resource "aws_cognito_user_pool" "appsync_pool" {
  name = "AppSyncCognitoUserPool"

  alias_attributes           = ["email"]
  auto_verified_attributes   = ["email"]

  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_numbers   = true
    require_symbols   = true
    require_uppercase = true
    temporary_password_validity_days = 7
  }
}

resource "aws_cognito_user_pool_domain" "appsync_pool_domain" {
  domain       = "myappsyncdomain" 
  user_pool_id = aws_cognito_user_pool.appsync_pool.id
}

resource "aws_cognito_user_pool_client" "appsync_pool_client" {
  name         = "AppSyncCognitoUserPoolClient"
  user_pool_id = aws_cognito_user_pool.appsync_pool.id
  generate_secret = false

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  # OAuth settings
  allowed_oauth_flows = ["code", "implicit"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes = ["phone", "email", "openid", "profile", "aws.cognito.signin.user.admin"]
  callback_urls = [var.callbackUrl]
  logout_urls   = [var.logoutUrl]

  supported_identity_providers = ["COGNITO"]
}

output "cognito_hosted_ui_url" {
  value = "https://${aws_cognito_user_pool_domain.appsync_pool_domain.domain}.auth.${var.region}.amazoncognito.com/login?response_type=token&client_id=${aws_cognito_user_pool_client.appsync_pool_client.id}&redirect_uri=${var.callbackUrl}"
}

output "cognito_client_id" {
  value = aws_cognito_user_pool_client.appsync_pool_client.id
  description = "Cognito User Pool Client ID"
}

output "callback_url" {
  value = var.callbackUrl
  description = "Callback URL for OAuth2.0"
}

output "cognito_domain" {
  value = aws_cognito_user_pool_domain.appsync_pool_domain.domain
  description = "Cognito User Pool domain"
}

output "aws_region" {
  value = var.region
  description = "AWS region for the resources"
}
