#!/bin/bash -v
sudo apt update -y
sudo apt install python3-pip -y
sudo pip3 install flask
sudo mkdir -p /var/www/
sudo cat <<EOF > /var/www/server.py
from flask import Flask, request
import jwt
import requests
import base64
import json

app = Flask(__name__)

@app.route('/health', methods=['GET'])
def health():
    return 'OK', 200

@app.route('/', methods=['GET'])
def index():
    return 'Secret information', 200

@app.route('/me', methods=['GET'])
def me():
    try:
        # Step 1: Extract the JWT from the x-amzn-oidc-data header
        encoded_jwt = request.headers.get('X-AMZN-OIDC-DATA')
        if not encoded_jwt:
            return 'Missing token', 400

        # Step 2: Decode the JWT headers to get the key ID (kid)
        jwt_headers = encoded_jwt.split('.')[0]
        decoded_jwt_headers = base64.urlsafe_b64decode(jwt_headers + '==')  # Add padding if necessary
        decoded_jwt_headers_str = decoded_jwt_headers.decode("utf-8")
        decoded_json = json.loads(decoded_jwt_headers_str)
        kid = decoded_json['kid']

        # Determine the region from the request or set it explicitly
        region = 'us-east-1'  # Set your region here

        # Step 3: Get the public key from the regional endpoint
        url = f'https://public-keys.auth.elb.{region}.amazonaws.com/{kid}'
        req = requests.get(url)
        if req.status_code != 200:
            return 'Failed to retrieve public key', 500
        pub_key = req.text

        # Step 4: Decode the JWT payload
        payload = jwt.decode(encoded_jwt, pub_key, algorithms=['ES256'])

        # Extract user information and return it
        user_info = payload  # Use appropriate key for user info, e.g., payload["username"]
        return f'User info extracted from JWT: {user_info}', 200

    except jwt.PyJWTError as e:
        # Handle JWT decode errors
        return f'An error occurred while decoding JWT: {str(e)}', 400
    except Exception as e:
        # Handle other possible errors
        return f'An error occurred: {str(e)}', 500

if __name__ == '__main__':
    # Run the application
    app.run(host='0.0.0.0', port=80)  # Use appropriate host and port
EOF
sudo python3.10 /var/www/server.py &