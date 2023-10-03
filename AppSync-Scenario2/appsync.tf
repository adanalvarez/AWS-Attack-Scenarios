resource "aws_appsync_graphql_api" "main" {
  authentication_type = "AWS_IAM"
  name                = "appsync-bank-transactions"
  schema              = file("${path.module}/schema.graphql")

  log_config {
    cloudwatch_logs_role_arn = aws_iam_role.graph_log_role.arn
    field_log_level          = "ALL"
    exclude_verbose_content  = true
  }
  additional_authentication_provider {
    authentication_type = "AMAZON_COGNITO_USER_POOLS"
    user_pool_config {
            app_id_client_regex = aws_cognito_user_pool_client.appsync_pool_client.id
            aws_region          = var.region
            user_pool_id        = aws_cognito_user_pool.appsync_pool.id
          }
  }
}

# APPSYNC Permissions for logging
data "aws_iam_policy_document" "graph_log_role_policy_document" {
  statement {
    sid = "1"
    actions = [
      "sts:AssumeRole",
    ]
    principals {
      type        = "Service"
      identifiers = ["appsync.amazonaws.com"]
    }
  }

}

resource "aws_iam_role" "graph_log_role" {
  name = "graph_log_role"

  assume_role_policy = data.aws_iam_policy_document.graph_log_role_policy_document.json
}

data "aws_iam_policy_document" "graph_log_policy_policy_document" {
  statement {
    sid = "1"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "graph_log" {
  name   = "graph_log_policy"
  role   = aws_iam_role.graph_log_role.id
  policy = data.aws_iam_policy_document.graph_log_policy_policy_document.json
}

# Datasource
# DynamoDB Data Source for savingAccounts table
resource "aws_appsync_datasource" "savingAccounts" {
  api_id = aws_appsync_graphql_api.main.id
  name   = "savingAccountsDatasource"
  type   = "AMAZON_DYNAMODB"

  dynamodb_config {
    table_name = "savingAccounts"
  }

  service_role_arn = aws_iam_role.appsync_dynamodb_role.arn
}

# IAM role for AppSync to access DynamoDB
resource "aws_iam_role" "appsync_dynamodb_role" {
  name = "AppSyncDynamoDBRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "appsync.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "appsync_dynamodb_access" {
  name = "AppSyncDynamoDBAccess"
  role = aws_iam_role.appsync_dynamodb_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem",
          "dynamodb:DeleteItem"
        ],
        Resource = [
          "arn:aws:dynamodb:${var.region}:${var.accountId}:table/savingAccounts",
          "arn:aws:dynamodb:${var.region}:${var.accountId}:table/savingAccounts/*",
          "arn:aws:dynamodb:${var.region}:${var.accountId}:table/checkingAccounts",
          "arn:aws:dynamodb:${var.region}:${var.accountId}:table/checkingAccounts/*",
          "arn:aws:dynamodb:${var.region}:${var.accountId}:table/transactionHistory",
          "arn:aws:dynamodb:${var.region}:${var.accountId}:table/transactionHistory/*"
        ]
      }
    ]
  })
}

resource "aws_appsync_resolver" "populateAccounts_resolver" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "populateAccounts"
  data_source = aws_appsync_datasource.savingAccounts.name
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
  code = <<-EOT
import { util } from '@aws-appsync/utils'

export function request(ctx) {
	const { savingAccounts, checkingAccounts } = ctx.args

	const savings = savingAccounts.map(({ accountNumber, ...rest }) => {
		return {
			table: 'savingAccounts',
			operation: 'PutItem',
			key: util.dynamodb.toMapValues({ accountNumber }),
			attributeValues: util.dynamodb.toMapValues(rest),
		}
	})

	const checkings = checkingAccounts.map(({ accountNumber, ...rest }) => {
		return {
			table: 'checkingAccounts',
			operation: 'PutItem',
			key: util.dynamodb.toMapValues({ accountNumber }),
			attributeValues: util.dynamodb.toMapValues(rest),
		}
	})
	return {
		version: '2018-05-29',
		operation: 'TransactWriteItems',
		transactItems: [...savings, ...checkings],
	}
}

export function response(ctx) {
	if (ctx.error) {
		util.error(ctx.error.message, ctx.error.type, null, ctx.result.cancellationReasons)
	}
	const { savingAccounts: sInput, checkingAccounts: cInput } = ctx.args
	const keys = ctx.result.keys
	const savingAccounts = sInput.map((_, i) => keys[i])
	const sLength = sInput.length
	const checkingAccounts = cInput.map((_, i) => keys[sLength + i])
	return { savingAccounts, checkingAccounts }
}
EOT

}

resource "aws_appsync_resolver" "transferMoney_resolver" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Mutation"
  field       = "transferMoney"
  data_source = aws_appsync_datasource.savingAccounts.name
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
  code = <<-EOT
import { util } from '@aws-appsync/utils'

export function request(ctx) {
	const transactions = ctx.args.transactions

	const savings = []
	const checkings = []
	const history = []
	transactions.forEach((t) => {
		const { savingAccountNumber, checkingAccountNumber, amount } = t
		savings.push({
			table: 'savingAccounts',
			operation: 'UpdateItem',
			key: util.dynamodb.toMapValues({ accountNumber: savingAccountNumber }),
			update: {
				expression: 'SET balance = balance - :amount',
				expressionValues: util.dynamodb.toMapValues({ ':amount': amount }),
			},
		})
		checkings.push({
			table: 'checkingAccounts',
			operation: 'UpdateItem',
			key: util.dynamodb.toMapValues({ accountNumber: checkingAccountNumber }),
			update: {
				expression: 'SET balance = balance + :amount',
				expressionValues: util.dynamodb.toMapValues({ ':amount': amount }),
			},
		})
		history.push({
			table: 'transactionHistory',
			operation: 'PutItem',
			key: util.dynamodb.toMapValues({ transactionId: util.autoId() }),
			attributeValues: util.dynamodb.toMapValues({
				from: savingAccountNumber,
				to: checkingAccountNumber,
				amount,
			}),
		})
	})

	return {
		version: '2018-05-29',
		operation: 'TransactWriteItems',
		transactItems: [...savings, ...checkings, ...history],
	}
}

export function response(ctx) {
	if (ctx.error) {
		util.error(ctx.error.message, ctx.error.type, null, ctx.result.cancellationReasons)
	}
	const tInput = ctx.args.transactions
	const tLength = tInput.length
	const keys = ctx.result.keys
	const savingAccounts = tInput.map((_, i) => keys[tLength * 0 + i])
	const checkingAccounts = tInput.map((_, i) => keys[tLength * 1 + i])
	const transactionHistory = tInput.map((_, i) => keys[tLength * 2 + i])
	return { savingAccounts, checkingAccounts, transactionHistory }
}
EOT

}

resource "aws_appsync_resolver" "getAccounts_resolver" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Query"
  field       = "getAccounts"
  data_source = aws_appsync_datasource.savingAccounts.name
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
  code = <<-EOT
import { util } from '@aws-appsync/utils'

export function request(ctx) {
	const { savingAccountNumbers, checkingAccountNumbers } = ctx.args

	const savings = savingAccountNumbers.map((accountNumber) => {
		return { table: 'savingAccounts', key: util.dynamodb.toMapValues({ accountNumber }) }
	})
	const checkings = checkingAccountNumbers.map((accountNumber) => {
		return { table: 'checkingAccounts', key: util.dynamodb.toMapValues({ accountNumber }) }
	})
	return {
		version: '2018-05-29',
		operation: 'TransactGetItems',
		transactItems: [...savings, ...checkings],
	}
}

export function response(ctx) {
	if (ctx.error) {
		util.error(ctx.error.message, ctx.error.type, null, ctx.result.cancellationReasons)
	}

	const { savingAccountNumbers: sInput, checkingAccountNumbers: cInput } = ctx.args
	const items = ctx.result.items
	const savingAccounts = sInput.map((_, i) => items[i])
	const sLength = sInput.length
	const checkingAccounts = cInput.map((_, i) => items[sLength + i])
	return { savingAccounts, checkingAccounts }
}
EOT

}

resource "aws_appsync_resolver" "getMyAccounts_resolver" {
  api_id      = aws_appsync_graphql_api.main.id
  type        = "Query"
  field       = "getMyAccounts"
  data_source = aws_appsync_datasource.savingAccounts.name
  runtime {
    name            = "APPSYNC_JS"
    runtime_version = "1.0.0"
  }
  code = <<-EOT
import { util } from '@aws-appsync/utils'

export function request(ctx) {
    console.log(ctx)
    return {
        version: '2018-05-29',
        operation: 'TransactGetItems',
        transactItems: [
            { table: 'savingAccounts', key: util.dynamodb.toMapValues({ accountNumber: ctx.identity.sub }) },
            { table: 'checkingAccounts', key: util.dynamodb.toMapValues({ accountNumber: ctx.identity.sub }) }
        ],
    };
}

export function response(ctx) {
    if (ctx.error) {
        util.error(ctx.error.message, ctx.error.type, null, ctx.result.cancellationReasons);
    }

    const items = ctx.result.items;
    const savingAccounts = [items[0]];
    const checkingAccounts = [items[1]];
    return { savingAccounts, checkingAccounts };
}
EOT

}