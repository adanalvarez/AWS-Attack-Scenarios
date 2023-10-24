# ALB - Sensitive Data Access via ALB Rule Manipulation

## Overview

This setup establishes an AWS Application Load Balancer (ALB) with integrated AWS Cognito authentication, directing traffic to an EC2 instance running a simple web application. Authenticated users can access a 'secret' area within the app and retrieve personal data, simulating a typical user data protection scenario.

## Prerequisites

- AWS CLI configured with necessary permissions.
- Terraform installed.
- A domain in AWS.

## Deploying the Infrastructure

First of all change the domain. For testing I had test.adanalvarez.click. It has to be changed in `domain.tf` and in the `shared.auto.tfvars.json`

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

4. **Access the APP**: After deployment, you'll receive a URL for the ALB that you can test ( but it will fail when redirected to Cognito). You'll have to wait till the domain is properly working.

## Attacking the Infrastructure

The purpose of this exercise is to illustrate how attackers could potentially exploit an AWS infrastructure, as outlined in the article. Here, we simulate an attack on the Application Load Balancer (ALB) by manipulating its rules to bypass authentication and inject malicious scripts for data exfiltration.

1. **Manipulate ALB Rules to Bypass Authentication:**

Identify the ALB listener ARN created by Terraform.
Create a new rule with conditions to check for a custom header, using the condition from `SampleAttackCode/bypassRule.json`.
Apply this rule to the ALB, setting its priority to ensure it's evaluated before the default rule.

2. **Inject a Malicious Script via ALB Fixed Response:**

For this attack you will need to set a server to recive the information. It has to be using HTTPS and if possible have a valid domain.

Identify the ALB listener ARN created by Terraform.
Create a new rule, with priority 1, with a condition that will trigger if the cookie contains *bypass* such as `SampleAttackCode/bypassCookieRule.json`, the action configuration should be equal to the default rule.
Create a new rule, with priority 2, with a condition that will trigger if there is a custom header called Bypass that is true such as `SampleAttackCode/bypassFromScriptRule.json`, the action configuration should be equal to the default rule.
Create a new rule, with priority 3, with a condition that will trigger if the cookie contains *AWSELBAuthSessionCookie* such as `SampleAttackCode/bypassScript.json`, the action configuration should be a fixed response such as `SampleAttackCode/maliciousAction.json`. Remember to change your domain and the malicious destination.

## Understanding the Attacks

**Bypass Authentication:** The attacker creates a rule that looks for a specific 'Bypass' header in the request. If this header is present, the rule allows the request to reach the application without needing to pass through Cognito authentication, exploiting the ALB's rule priority system.

**Malicious Script Injection:** The attacker creates multiple rules and with them a malicious script will be executed on the victim's browser exfiltrating the data from /me to a server controlled by the attacker. The additional rules allow the application to work as expected for the user. 

## Cleanup

To avoid incurring additional charges, ensure you destroy the Terraform-managed resources once done:

```bash
terraform destroy
```

⚠️ **Warning** ⚠️

> The content and techniques described here are meant for educational and awareness purposes only. Always be cautious when testing and use only in safe, controlled environments. Unauthorized use or misuse can lead to legal consequences and potential harm.