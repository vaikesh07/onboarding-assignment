// http-client.js - This program performs an HTTP GET request and prints
// the content received from "data" events to the console.

// Import the built-in Node.js 'http' module.
// This module provides functions for making HTTP requests.
const http = require('http');

// Get the URL from the first command-line argument.
// process.argv[0] is 'node'
// process.argv[1] is the script file path (e.g., 'http-client.js')
// process.argv[2] is the URL provided by the user.
const url = process.argv[2];

// Check if a URL was provided.
if (!url) {
    console.error("Usage: node http-client.js <URL>");
    process.exit(1); // Exit with an error code if the URL is missing.
}

// Perform an HTTP GET request to the specified URL.
// http.get() is a shortcut method that simplifies GET requests.
// It takes the URL as the first argument and a callback function as the second.
http.get(url, (response) => {
    // The 'response' object is a Node.js Stream.
    // It emits events as data is received.

    // Set the encoding of the response stream to 'utf8'.
    // This ensures that the 'data' events will emit strings instead of Buffer objects.
    response.setEncoding('utf8');

    // Listen for the 'data' event.
    // This event is emitted whenever a chunk of data is received from the server.
    // The 'chunk' argument will be a string because we set the encoding to 'utf8'.
    response.on('data', (chunk) => {
        // Print each received data chunk to the console.
        // console.log() automatically adds a newline character after each output.
        console.log(chunk);
    });

    // Listen for the 'error' event.
    // This event is emitted if there's any error during the HTTP request
    // (e.g., network error, invalid URL, DNS lookup failure).
    response.on('error', (error) => {
        // Print the error message to the console's error stream.
        console.error(`HTTP request error: ${error.message}`);
    });

    // Listen for the 'end' event.
    // This event is emitted when the entire response has been received.
    response.on('end', () => {
        // You could add logic here if you need to do something after all data is received,
        // for example, process the complete response, but for this exercise,
        // we just need to print data as it comes.
        // console.log("--- End of response ---"); // Optional: for debugging/completeness
    });

}).on('error', (error) => {
    // This 'error' handler catches errors that occur *before* the response is received,
    // such as an invalid URL or network connectivity issues that prevent the request from starting.
    console.error(`Could not complete HTTP request: ${error.message}`);
});
