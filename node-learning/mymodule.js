// mymodule.js - This module provides a function to read a directory
// and filter files by extension, passing the result to a callback.

// Import the Node.js 'fs' (filesystem) and 'path' modules.
const fs = require('fs');
const path = require('path');

module.exports = function (directoryPath, filterExtension, callback) {
    // Construct the expected extension with a leading dot, as path.extname() includes it.
    const expectedExtension = `.${filterExtension}`;

    // Asynchronously read the contents of the specified directory.
    fs.readdir(directoryPath, (err, list) => {
        // If an error occurs during directory reading (e.g., directory not found, permissions error),
        // call the provided callback function with the error and return early.
        if (err) {
            return callback(err); // Idiomatic Node.js callback: err as the first argument
        }

        // If no error, filter the list of filenames.
        // We use Array.prototype.filter() to create a new array containing only the matching files.
        const filteredList = list.filter(filename => {
            // Get the extension of the current file using path.extname().
            const currentFileExtension = path.extname(filename);

            // Compare the extracted extension with the expected extension.
            // Only include files that have the matching extension.
            return currentFileExtension === expectedExtension;
        });

        // Call the callback function with null for the error (indicating success)
        // and the filtered list of filenames as the data.
        callback(null, filteredList);
    });
};
