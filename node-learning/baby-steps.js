// This program calculates the sum of numbers passed as command-line arguments.

// process.argv is an array containing the command-line arguments.
// The first element is 'node', the second is the path to the JavaScript file.
// Subsequent elements are the actual command-line arguments.
// Example: node baby-steps.js 10 20 30
// process.argv will be ['node', '/path/to/baby-steps.js', '10', '20', '30']

let sum = 0; // Initialize a variable to store the sum.

// Loop through the command-line arguments starting from the third element (index 2).
// This skips 'node' and the script file path.
for (let i = 2; i < process.argv.length; i++) {
    // Get the current argument, which is a string.
    const arg = process.argv[i];

    // Convert the string argument to a number using Number() and add it to the sum.
    // Number() can convert strings like "10" to the number 10.
    sum += Number(arg);
}

// Print the final sum to the console (standard output).
console.log(sum);
