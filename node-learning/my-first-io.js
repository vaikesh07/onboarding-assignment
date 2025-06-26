// This program reads a file synchronously and counts the number of newlines.

// Import the Node.js 'fs' (filesystem) module.
// The 'fs' module provides an API for interacting with the file system.
const fs = require('fs');

// The file path is provided as the first command-line argument.
// process.argv[0] is 'node'
// process.argv[1] is the script file path (e.g., 'my-first-io.js')
// process.argv[2] is the actual command-line argument we need: the file path.
const filePath = process.argv[2];

// Use fs.readFileSync() to read the file synchronously.
// This means the program will block until the file is fully read.
// The second argument 'utf8' specifies the encoding, which ensures the content
// is returned as a string rather than a Buffer object.
try {
    const fileContent = fs.readFileSync(filePath, 'utf8');

    // Split the file content by the newline character ('\n').
    // This will create an array where each element is a line from the file.
    // For example, "line1\nline2\nline3" will become ["line1", "line2", "line3", ""].
    // The last element will be an empty string if the file ends with a newline.
    const lines = fileContent.split('\n');

    // The number of newlines is equivalent to the number of elements in the array
    // minus one, because a file with N newlines will produce N+1 segments when split by '\n'.
    // If the file is empty or has no newlines, this will correctly result in 0 or 1 element,
    // making (lines.length - 1) the correct count of newlines.
    const numberOfNewlines = lines.length - 1;

    // Print the count of newlines to the console.
    console.log(numberOfNewlines);
} catch (error) {
    // Basic error handling: if the file cannot be read (e.g., file not found),
    // print an error message to the console.
    console.error(`Error reading file: ${error.message}`);
}
