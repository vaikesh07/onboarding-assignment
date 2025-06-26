// http-json-api-server.js - An HTTP server that serves JSON data based on
// GET requests to specific API endpoints.

// Import the built-in Node.js 'http' module for creating HTTP servers.
const http = require('http');

// Import the built-in Node.js 'url' module for parsing URLs.
// Using URL constructor is generally preferred for full URL parsing.
const { URL } = require('url');

// Get the port number from the first command-line argument.
const port = Number(process.argv[2]);

// Basic input validation: Check if a valid port number was provided.
if (isNaN(port) || port <= 0) {
    console.error("Usage: node http-json-api-server.js <port_number>");
    console.error("Please provide a valid port number to listen on.");
    process.exit(1); // Exit if the port is invalid.
}

// Create an HTTP server instance.
// The callback function (req, res) is executed for every incoming HTTP request.
const server = http.createServer((req, res) => {
    // Parse the request URL. The second argument 'base' is needed for the URL constructor
    // to correctly parse relative URLs like those coming from 'req.url'.
    // We use a dummy base URL as we are only interested in pathname and searchParams.
    const parsedUrl = new URL(req.url, 'http://example.com');

    // Check if the incoming request method is GET.
    if (req.method !== 'GET') {
        // If it's not a GET request, respond with a 405 Method Not Allowed status.
        res.writeHead(405, { 'Content-Type': 'text/plain' });
        res.end('Only GET requests are supported.\n');
        return; // End the request handling.
    }

    // Get the 'iso' query parameter from the URL's search parameters.
    const isoString = parsedUrl.searchParams.get('iso');

    // If 'iso' parameter is missing, send a 400 Bad Request error.
    if (!isoString) {
        res.writeHead(400, { 'Content-Type': 'text/plain' });
        res.end('Missing or invalid "iso" query parameter.\n');
        return;
    }

    // Attempt to parse the ISO string into a Date object.
    const date = new Date(isoString);

    // Validate if the parsed date is a valid date.
    // Date.parse() returns NaN for invalid dates.
    if (isNaN(date.getTime())) {
        res.writeHead(400, { 'Content-Type': 'text/plain' });
        res.end('Invalid ISO date format provided.\n');
        return;
    }

    let result; // Variable to hold the JSON response object.

    // Route the request based on the URL pathname.
    if (parsedUrl.pathname === '/api/parsetime') {
        // For '/api/parsetime' endpoint, return hour, minute, and second.
        result = {
            hour: date.getHours(),
            minute: date.getMinutes(),
            second: date.getSeconds()
        };
    } else if (parsedUrl.pathname === '/api/unixtime') {
        // For '/api/unixtime' endpoint, return UNIX epoch time in milliseconds.
        result = {
            unixtime: date.getTime()
        };
    } else {
        // If the path does not match any known API endpoint, send a 404 Not Found status.
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found\n');
        return; // End the request handling.
    }

    // If a valid result object was generated, send it as JSON.
    res.writeHead(200, { 'Content-Type': 'application/json' });
    // Convert the JavaScript object to a JSON string and send it as the response body.
    res.end(JSON.stringify(result));

    // Handle errors on the incoming request stream.
    req.on('error', (error) => {
        console.error(`Request stream error: ${error.message}`);
        if (!res.headersSent) {
            res.writeHead(500, { 'Content-Type': 'text/plain' });
            res.end('Server error during request processing.');
        }
    });

    // Handle errors on the outgoing response stream.
    res.on('error', (error) => {
        console.error(`Response stream error: ${error.message}`);
    });
});

// Start the server, making it listen for incoming HTTP connections on the specified port.
server.listen(port, () => {
    console.log(`HTTP JSON API Server listening on port ${port}`);
    console.log(`Endpoints: /api/parsetime?iso=... and /api/unixtime?iso=...`);
});

// Handle server-level errors (e.g., if the port is already in use).
server.on('error', (error) => {
    console.error(`Server startup error: ${error.message}`);
    process.exit(1); // Exit if the server cannot start.
});
