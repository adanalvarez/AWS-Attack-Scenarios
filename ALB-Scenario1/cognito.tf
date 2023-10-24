resource "aws_cognito_user_pool" "app_pool" {
  name = "AppCognitoUserPool"

  username_attributes = ["email"]

  password_policy {
    minimum_length                   = 8
    require_lowercase                = true
    require_numbers                  = true
    require_symbols                  = true
    require_uppercase                = true
    temporary_password_validity_days = 7
  }

  admin_create_user_config {
    allow_admin_create_user_only = true
  }
}

resource "aws_cognito_user_pool_domain" "app_pool_domain" {
  domain       = "myapppooldomain"
  user_pool_id = aws_cognito_user_pool.app_pool.id
}

resource "aws_cognito_user_pool_client" "app_pool_client" {
  name            = "AppCognitoUserPoolClient"
  user_pool_id    = aws_cognito_user_pool.app_pool.id
  generate_secret = true

  explicit_auth_flows = [
    "ALLOW_USER_SRP_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_PASSWORD_AUTH"
  ]

  # OAuth settings
  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid"]
  callback_urls                        = [var.callbackUrl]
  logout_urls                          = [var.logoutUrl]

  supported_identity_providers = ["COGNITO"]
}