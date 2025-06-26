// This program reads a file asynchronously and counts the number of newlines.

// Import the Node.js 'fs' (filesystem) module.
// The 'fs' module provides an API for interacting with the file system.
const fs = require('fs');

// The file path is provided as the first command-line argument.
// process.argv[0] is 'node'
// process.argv[1] is the script file path (e.g., 'my-first-async-io.js')
// process.argv[2] is the actual command-line argument: the file path.
const filePath = process.argv[2];

// Use fs.readFile() to read the file asynchronously.
// This function does not block the execution of the rest of the script.
// It takes three arguments:
// 1. The path to the file.
// 2. The encoding ('utf8' to get a string instead of a Buffer).
// 3. A callback function that will be executed once the file reading is complete
//    or an error occurs.
fs.readFile(filePath, 'utf8', (err, data) => {
    // The callback function follows the Node.js convention:
    // The first argument 'err' will contain an Error object if an error occurred,
    // otherwise it will be null or undefined.
    // The second argument 'data' will contain the file's content (as a string due to 'utf8' encoding)
    // if the read operation was successful.

    if (err) {
        // If an error occurred during file reading (e.g., file not found, permissions issue),
        // print the error message to the console's error stream.
        console.error(`Error reading file: ${err.message}`);
        // It's good practice to return here to prevent further execution if there's an error.
        return;
    }

    // If there's no error, 'data' contains the file content as a string.

    // Split the file content by the newline character ('\n').
    // This creates an array where each element is a line from the file.
    // For example, "line1\nline2\nline3" will become ["line1", "line2", "line3", ""].
    const lines = data.split('\n');

    // The number of newlines is equal to the number of segments produced by the split
    // minus one. This is because N newlines will result in N+1 array elements.
    // If the file is empty or has no newlines, this correctly results in 0.
    const numberOfNewlines = lines.length - 1;

    // Print the calculated number of newlines to the console (standard output).
    console.log(numberOfNewlines);
});

// Note: Because fs.readFile is asynchronous, the program might finish executing
// before the callback function is called if there's other code here.
// However, for this specific problem, there's no other code, so it will wait
// for the file operation to complete via the event loop.
