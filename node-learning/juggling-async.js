// juggling-async.js - This program performs HTTP GET requests to three URLs
// provided as command-line arguments, collects all data from each, and
// prints them to the console in the order the URLs were provided.

// Import the built-in Node.js 'http' module for making HTTP requests.
const http = require('http');

// Import the 'bl' (Buffer List) package.
// This package helps in collecting data from a stream into a single buffer or string.
// Make sure you have installed it using: npm install bl
const bl = require('bl');

// Get the three URLs from the command-line arguments.
// process.argv[2], process.argv[3], and process.argv[4] will hold the URLs.
const urls = process.argv.slice(2); // Get arguments starting from index 2

// Basic input validation: Check if exactly three URLs were provided.
if (urls.length !== 3) {
    console.error("Usage: node juggling-async.js <URL1> <URL2> <URL3>");
    process.exit(1); // Exit with an error code if the wrong number of URLs is provided.
}

// Array to store the collected data for each URL.
// The index of this array will correspond to the original order of the URLs.
const results = [];

// Counter to keep track of how many HTTP requests have successfully completed.
let completedRequests = 0;

/**
 * Fetches content from a given URL and stores it in the results array.
 * Once all requests are complete, it prints the results in order.
 * @param {string} url The URL to fetch.
 * @param {number} index The original index of the URL in the input array.
 */
function fetchUrlContent(url, index) {
    http.get(url, (response) => {
        // Set the response encoding to utf8 to get strings directly.
        response.setEncoding('utf8');

        // Pipe the response stream into a 'bl' instance to collect all data.
        response.pipe(bl((err, data) => {
            if (err) {
                // If an error occurs during data collection or stream processing,
                // print the error and store the error message in results.
                console.error(`Error collecting data from ${url}: ${err.message}`);
                results[index] = `ERROR: ${err.message}`; // Store error for ordered output
            } else {
                // If successful, convert the collected data (Buffer) to a string
                // and store it in the 'results' array at its corresponding index.
                results[index] = data.toString();
            }

            // Increment the counter for completed requests.
            completedRequests++;

            // Check if all three requests have finished.
            if (completedRequests === 3) {
                // If all requests are done, iterate through the 'results' array
                // and print each stored string on a new line.
                // This ensures the output order matches the input URL order.
                results.forEach(content => {
                    console.log(content);
                });
            }
        }));

        // Handle errors on the response stream itself (e.g., connection reset).
        response.on('error', (error) => {
            // This error handler is specific to issues once a response object is received.
            console.error(`Response stream error for ${url}: ${error.message}`);
            // Mark this request as completed with an error if not already handled by bl.
            // This is a failsafe if bl's error handling doesn't catch it.
            if (results[index] === undefined) { // Only update if not already set by bl
                results[index] = `RESPONSE_STREAM_ERROR: ${error.message}`;
                completedRequests++;
                if (completedRequests === 3) {
                    results.forEach(content => {
                        console.log(content);
                    });
                }
            }
        });

    }).on('error', (error) => {
        // This 'error' handler catches errors that occur even before a response object is created,
        // such as DNS lookup failures, invalid URLs, or initial network connection issues.
        console.error(`HTTP GET request failed for ${url}: ${error.message}`);
        results[index] = `REQUEST_ERROR: ${error.message}`; // Store error for ordered output
        completedRequests++;
        if (completedRequests === 3) {
            results.forEach(content => {
                console.log(content);
            });
        }
    });
}

// Loop through each URL and initiate the asynchronous request.
urls.forEach((url, index) => {
    fetchUrlContent(url, index);
});
