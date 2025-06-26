// http-file-server.js - An HTTP server that serves the content of a
// specified text file for every incoming request.

// Import the built-in Node.js 'http' module for creating HTTP servers.
const http = require('http');

// Import the built-in Node.js 'fs' (filesystem) module for file operations.
const fs = require('fs');

// Get the port number from the first command-line argument.
const port = Number(process.argv[2]);

// Get the file path to serve from the second command-line argument.
const filePath = process.argv[3];

// Basic input validation: Check if both arguments are provided and valid.
if (isNaN(port) || port <= 0) {
    console.error("Usage: node http-file-server.js <port_number> <file_path>");
    console.error("Please provide a valid port number.");
    process.exit(1);
}

if (!filePath) {
    console.error("Usage: node http-file-server.js <port_number> <file_path>");
    console.error("Please provide the path to the file to serve.");
    process.exit(1);
}

// Create an HTTP server instance.
// http.createServer() takes a callback function that is executed for each
// incoming HTTP request.
// The callback receives two arguments:
// - 'request' (or 'req'): An object representing the incoming HTTP request.
// - 'response' (or 'res'): An object used to send data back to the client.
const server = http.createServer((req, res) => {
    // Set the HTTP response header.
    // status code 200 means "OK".
    // 'Content-Type': 'text/plain' tells the client that the response body
    // will be plain text. You could also use 'text/html' for HTML files, etc.
    res.writeHead(200, { 'Content-Type': 'text/plain' });

    // Create a readable stream from the specified file.
    // fs.createReadStream() returns a new ReadStream object.
    const fileStream = fs.createReadStream(filePath);

    // Pipe the readable file stream directly to the writable HTTP response stream.
    // This is a highly efficient way to serve files, as data chunks are read
    // from the file and immediately written to the response, without buffering
    // the entire file in memory.
    fileStream.pipe(res);

    // Handle errors that might occur during reading the file stream.
    fileStream.on('error', (error) => {
        console.error(`Error reading file stream: ${error.message}`);
        // If an error occurs (e.g., file not found, permissions), send a 500 Internal Server Error.
        res.writeHead(500, { 'Content-Type': 'text/plain' });
        res.end(`Internal Server Error: Could not read file. ${error.message}`);
    });

    // Handle errors that might occur if the client's connection breaks or has issues.
    req.on('error', (error) => {
        console.error(`Request error: ${error.message}`);
        // Note: For client-side errors during a request, it's often too late
        // to send a proper HTTP response if headers have already been sent.
        // This is more for logging.
    });

    res.on('error', (error) => {
        console.error(`Response error: ${error.message}`);
        // Similar to request error, often for logging unexpected issues.
    });
});

// Start the server, making it listen for incoming HTTP connections on the specified port.
server.listen(port, () => {
    console.log(`HTTP File Server listening on port ${port}`);
    console.log(`Serving file: ${filePath}`);
});

// Handle server-level errors (e.g., port already in use).
server.on('error', (error) => {
    console.error(`Server error: ${error.message}`);
    // If the server fails to start, this will catch the error.
});
