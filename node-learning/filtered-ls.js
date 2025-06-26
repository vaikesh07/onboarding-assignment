// This program lists files in a given directory, filtered by file extension.
// It uses asynchronous I/O with fs.readdir().

// Import the Node.js 'fs' (filesystem) and 'path' modules.
// 'fs' is used for reading directory contents.
// 'path' is used for working with file paths, specifically to get the extension.
const fs = require('fs');
const path = require('path');

// Get the directory path and file extension from command-line arguments.
// process.argv[0] is 'node'
// process.argv[1] is the script file path (e.g., 'filtered-ls.js')
// process.argv[2] is the directory path.
// process.argv[3] is the file extension to filter by (without the leading dot).
const directoryPath = process.argv[2];
const filterExtension = process.argv[3]; // e.g., 'txt'

// Check if both arguments are provided.
if (!directoryPath || !filterExtension) {
    console.error("Usage: node filtered-ls.js <directory_path> <file_extension>");
    process.exit(1); // Exit with an error code
}

// Read the contents of the directory asynchronously.
// fs.readdir takes the directory path and a callback function.
fs.readdir(directoryPath, (err, list) => {
    // The callback function has two arguments:
    // 'err': An Error object if something went wrong, otherwise null.
    // 'list': An array of strings, where each string is the name of a file or directory
    //         within the specified 'directoryPath'.

    if (err) {
        // If an error occurred (e.g., directory not found, permissions issue),
        // print the error message to the console's error stream.
        console.error(`Error reading directory: ${err.message}`);
        return; // Exit the function if there's an error.
    }

    // Iterate over each item (filename) in the list array.
    list.forEach(filename => {
        // Use path.extname() to get the extension of the current file.
        // It returns the extension including the leading dot (e.g., '.txt', '.js').
        const fileExtension = path.extname(filename);

        // Construct the full filter extension with a leading dot.
        // This is necessary because path.extname() returns the dot,
        // but the problem statement says the input filterExtension won't have it.
        const expectedExtension = `.${filterExtension}`;

        // Compare the extracted file extension with the expected extension.
        // If they match, print the filename to the console.
        if (fileExtension === expectedExtension) {
            console.log(filename);
        }
    });
});
