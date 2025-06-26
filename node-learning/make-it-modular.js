// make-it-modular.js - This program uses a custom module (mymodule.js)
// to list files in a directory filtered by extension.

// Import our custom module. The './' indicates it's a local file.
// The '.js' extension is optional but included here for clarity.
const mymodule = require('./mymodule.js');

// Get the directory path and file extension from command-line arguments.
// process.argv[2] is the directory path.
// process.argv[3] is the file extension to filter by (without the leading dot).
const directoryPath = process.argv[2];
const filterExtension = process.argv[3];

// Check if both required command-line arguments are provided.
if (!directoryPath || !filterExtension) {
    console.error("Usage: node make-it-modular.js <directory_path> <file_extension>");
    process.exit(1); // Exit the program with an error code if arguments are missing.
}

// Call the function exported by our custom module.
// Pass the directory path, the filter extension, and a callback function.
mymodule(directoryPath, filterExtension, (err, filteredFiles) => {
    // This is the callback function that will be executed once the module
    // has finished its asynchronous operation (reading and filtering the directory).

    // Check if an error was passed from the module.
    if (err) {
        // If an error occurred, print an informative error message to the console.
        console.error(`An error occurred: ${err.message}`);
        // No need to return here as there's nothing else to do in case of an error for this program.
        return;
    }

    // If no error occurred, 'filteredFiles' will contain the array of matching filenames.
    // Iterate over each filename in the 'filteredFiles' array.
    filteredFiles.forEach(filename => {
        // Print each filtered filename to the console on a new line.
        console.log(filename);
    });
});
