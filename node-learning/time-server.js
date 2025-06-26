// time-server.js - A TCP time server that returns the current date and time
// in "YYYY-MM-DD hh:mm" format to each connected client, then closes the connection.

// Import the built-in Node.js 'net' module, which provides an asynchronous
// network API for creating stream-based TCP servers and clients.
const net = require('net');

// Get the port number from the first command-line argument.
// process.argv[2] holds the port number as a string.
const port = Number(process.argv[2]);

// Basic input validation: Check if a valid port number was provided.
// isNaN checks if the conversion to Number failed (e.g., if the argument wasn't a number).
if (isNaN(port) || port <= 0) {
    console.error("Usage: node time-server.js <port_number>");
    console.error("Please provide a valid port number as the first argument.");
    process.exit(1); // Exit the program with an error code if input is invalid.
}

/**
 * Helper function to zero-fill a single-digit number (e.g., 5 -> "05").
 * @param {number} i The number to pad.
 * @returns {string} The zero-filled string representation of the number.
 */
function zeroFill(i) {
    // If the number is less than 10, prepend a '0'.
    // Otherwise, convert it to a string as is.
    return (i < 10 ? '0' : '') + i;
}

/**
 * Formats the current date and time into "YYYY-MM-DD hh:mm" string.
 * @returns {string} The formatted date and time string.
 */
function getCurrentDateTime() {
    const date = new Date(); // Create a new Date object representing the current moment.

    // Extract date components. Note: getMonth() is 0-indexed.
    const year = date.getFullYear();
    const month = zeroFill(date.getMonth() + 1); // Add 1 because months are 0-indexed (0=Jan, 11=Dec).
    const day = zeroFill(date.getDate()); // Day of the month.
    const hours = zeroFill(date.getHours()); // 24-hour format.
    const minutes = zeroFill(date.getMinutes()); // Minutes.

    // Assemble the string in the required format.
    return `${year}-${month}-${day} ${hours}:${minutes}`;
}

// Create a TCP server instance.
// net.createServer() takes a connection listener function as an argument.
// This function is called every time a new client connects to the server.
const server = net.createServer((socket) => {
    // 'socket' is a Node.js Duplex Stream object representing the connection
    // between the server and the client. Data can be both read from and written to it.

    // 1. Get the current formatted date and time.
    const dateTimeString = getCurrentDateTime();

    // 2. Write the formatted string followed by a newline character to the socket.
    // socket.end() is used to write data AND close the socket after the data is written.
    socket.end(dateTimeString + '\n');

    // Optional: Add a 'data' listener to log anything received from the client.
    // For a time server, clients typically don't send data, but it's good practice
    // for debugging or more complex servers.
    // socket.on('data', (data) => {
    //     console.log(`Received data from client: ${data.toString()}`);
    // });

    // Handle potential errors on the socket connection.
    socket.on('error', (error) => {
        console.error(`Socket error: ${error.message}`);
    });

    // Optional: Log when a client connects and disconnects for debugging purposes.
    // socket.on('connect', () => {
    //     console.log('Client connected.');
    // });
    // socket.on('end', () => {
    //     console.log('Client disconnected.');
    // });
});

// Start the server, making it listen for incoming connections on the specified port.
// server.listen() binds the server to a network address and port.
server.listen(port, () => {
    console.log(`TCP Time Server listening on port ${port}`);
});

// Handle server-level errors (e.g., port already in use).
server.on('error', (error) => {
    console.error(`Server error: ${error.message}`);
});
