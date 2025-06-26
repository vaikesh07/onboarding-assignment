// http-uppercaserer.js - An HTTP server that converts incoming POST request
// body characters to upper-case and returns it to the client.

// Import the built-in Node.js 'http' module for creating HTTP servers.
const http = require('http');

// Import the 'through2-map' package. This is a stream transform module
// that allows mapping chunks of data as they pass through a stream.
// Make sure you have installed it using: npm install through2-map
const map = require('through2-map');

// Get the port number from the first command-line argument.
const port = Number(process.argv[2]);

// Basic input validation: Check if a valid port number was provided.
if (isNaN(port) || port <= 0) {
    console.error("Usage: node http-uppercaserer.js <port_number>");
    console.error("Please provide a valid port number to listen on.");
    process.exit(1); // Exit if the port is invalid.
}

// Create an HTTP server instance.
// The callback function (req, res) is executed for every incoming HTTP request.
const server = http.createServer((req, res) => {
    // Check if the incoming request method is POST.
    if (req.method !== 'POST') {
        // If it's not a POST request, respond with a 405 Method Not Allowed status.
        res.writeHead(405, { 'Content-Type': 'text/plain' });
        res.end('Only POST requests are supported.\n');
        return; // End the request handling.
    }

    // If the request method is POST:
    // Set the response header to indicate plain text content.
    res.writeHead(200, { 'Content-Type': 'text/plain' });

    // Pipe the incoming request stream (req) to the 'map' transform stream.
    // The map function will be applied to each data chunk received.
    // In this case, the function converts the chunk to a string and then to uppercase.
    // The transformed chunks are then piped directly to the response stream (res).
    req.pipe(map(function (chunk) {
        // 'chunk' here is a Buffer object.
        // 1. Convert the Buffer chunk to a string using toString().
        // 2. Convert the string to uppercase using toUpperCase().
        // 3. Return the uppercased string. This returned value becomes the
        //    output chunk of the 'map' stream.
        return chunk.toString().toUpperCase();
    })).pipe(res); // Pipe the transformed data to the response.

    // Handle errors on the incoming request stream.
    req.on('error', (error) => {
        console.error(`Request stream error: ${error.message}`);
        // Attempt to send an error response if headers haven't been sent.
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
    console.log(`HTTP Uppercaserer Server listening on port ${port}`);
    console.log(`Ready to process POST requests.`);
});

// Handle server-level errors (e.g., if the port is already in use).
server.on('error', (error) => {
    console.error(`Server startup error: ${error.message}`);
    process.exit(1); // Exit if the server cannot start.
});
