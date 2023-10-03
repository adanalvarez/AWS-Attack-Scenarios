# AWS Attack Scenarios
A collection of scenarios and code samples demonstrating potential exploitation techniques in AWS services. Designed for educational purposes and security awareness.

## ⚠️ Disclaimer

The content and techniques described here are meant strictly for educational and awareness purposes. Unauthorized use or misuse outside of a controlled environment can lead to legal consequences and potential harm. Always proceed with caution and obtain necessary permissions.

## Scenarios Overview

1. **Cookie Theft via CloudFront Function (Folder: CloudFront-Scenario1)**:
    - **Description**: This scenario illustrates how an attacker can exploit a CloudFront setup to steal cookies from users. It employs a CloudFront function in conjunction with a simulated login page to demonstrate the theft.

2. **Data Exfiltration via Lambda Function Modification (Folder: CloudFront-Scenario2)**:
    - **Description**: In this setup, an attacker exploits a Lambda function associated with a CloudFront distribution. The attacker modifies the Lambda function to exfiltrate user request data to an external server.

3. **Persistence via AppSync API Key (Folder: AppSync-Scenario1)**:
    - **Description**: In this scenario, an attacker exploits an AppSync. The attacker adds an authentication provider to establish persistence. 

4. **Persistence via AppSync Resolver Modification (Folder: AppSync-Scenario2)**:
    - **Description**: This scenario shows how an attacker can modify the resolvers from AppSync to provide unique functionality to a user-controlled by them.

(More scenarios will be added as the repository grows.)