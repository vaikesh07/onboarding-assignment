// http-collect.js - This program performs an HTTP GET request, collects all
// the received data, and then prints the total character count and the
// complete string content.

// Import the built-in Node.js 'http' module for making HTTP requests.
const http = require('http');

// Import the 'bl' (Buffer List) package.
// This package simplifies collecting data from a stream into a single buffer or string.
// Make sure you have installed it using: npm install bl
const bl = require('bl');

// Get the URL from the first command-line argument.
// process.argv[2] holds the URL.
const url = process.argv[2];

// Basic input validation: Check if a URL was provided.
if (!url) {
    console.error("Usage: node http-collect.js <URL>");
    process.exit(1); // Exit the program with an error code if the URL is missing.
}

// Perform an HTTP GET request to the specified URL.
// The http.get() method takes the URL and a callback function.
http.get(url, (response) => {
    // The 'response' object is a Node.js Stream that emits data as it arrives.

    // Pipe the response stream directly into the 'bl' instance.
    // 'bl' will collect all the incoming data chunks.
    // When the 'end' event is emitted on the response stream, 'bl' will
    // call the provided callback function with the collected data.
    response.pipe(bl((err, data) => {
        // This callback is executed once all data from the stream has been collected by 'bl'.

        // 1. Handle any errors that occurred during the data collection or HTTP request.
        if (err) {
            console.error(`Error collecting data: ${err.message}`);
            return; // Exit the callback if there's an error.
        }

        // 2. Convert the collected data (which is a Buffer by default from 'bl') to a string.
        const completeString = data.toString();

        // 3. Print the number of characters received.
        // The .length property of a string gives its character count.
        console.log(completeString.length);

        // 4. Print the complete string of characters received.
        console.log(completeString);
    }));

    // Optional: You could also listen for errors directly on the response stream
    // for more granular error handling, though 'bl' will typically catch stream errors too.
    response.on('error', (error) => {
        console.error(`Response stream error: ${error.message}`);
    });

}).on('error', (error) => {
    // This 'error' handler catches errors that occur at the very beginning of the HTTP request,
    // before a 'response' object is even created (e.g., DNS lookup failure, network unreachable).
    console.error(`HTTP GET request failed: ${error.message}`);
});
