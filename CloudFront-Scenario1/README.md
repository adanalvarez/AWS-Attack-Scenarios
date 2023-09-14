# CloudFront - Cookie Theft via CloudFront Function

## Overview

This setup deploys an AWS CloudFront distribution backed by an S3 bucket. The bucket contains two files: `index.html` and `login.html`. The latter simulates a login page by setting a random cookie named `session-id` for the user.

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

4. **Access CloudFront**: After deployment, you'll receive a URL for the CloudFront distribution. Accessing it will lead you to `index.html`, which contains a link to `login.html`. The latter sets a random "cookie" to simulate a login page.

## Attacking the Infrastructure

The goal of this exercise is to demonstrate how attackers might harm an AWS infrastructure as detailed in the article:

1. **Create a new CloudFront Function**:
    - Use the code from `SampleAttackCode/function.js`.
    - Publish the function.
    - Associate it with the CloudFront distribution created by Terraform.
    - Set the event type to "Viewer Response".

2. **Host the Redirect Script**:
    - On a public server (e.g., an AWS EC2 instance), start a web server to serve the `SampleAttackCode/redirectScript.js`.
    - Ensure you replace `MALICIOUS_IP` in the script with the IP of your server or another destination where you want to capture cookies.

## Understanding the Attack

The CloudFront function checks for a custom cookie. If it's not present, it replaces the content with a redirect page pointing to a malicious script. This script captures the user's cookies and sends them to a malicious server. Once the data is captured, the malicious script sets a cookie to prevent further redirections and redirects the user back to the CloudFront URL.

## Cleanup

To avoid incurring additional charges, ensure you destroy the Terraform-managed resources once done:

```bash
terraform destroy
```

Also, remember to delete the function manually.

⚠️ **Warning** ⚠️

> The content and techniques described here are meant for educational and awareness purposes only. Always be cautious when testing and use only in safe, controlled environments. Unauthorized use or misuse can lead to legal consequences and potential harm.