resource "aws_dynamodb_table" "savingAccounts" {
  name           = "savingAccounts"
  hash_key       = "accountNumber"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "accountNumber"
    type = "S"
  }
}

resource "aws_dynamodb_table" "checkingAccounts" {
  name           = "checkingAccounts"
  hash_key       = "accountNumber"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "accountNumber"
    type = "S"
  }
}

resource "aws_dynamodb_table" "transactionHistory" {
  name           = "transactionHistory"
  hash_key       = "transactionId"
  billing_mode   = "PROVISIONED"
  read_capacity  = 5
  write_capacity = 5

  attribute {
    name = "transactionId"
    type = "S"
  }
}
