const express = require('express'); // used for serving html file to client
const http = require('http'); // used for creating http server
const WebSocket = require('ws'); // websocket for real time and bi-directional communication
const fs = require('fs'); // used to read log files and watch changes
const path = require('path');

// Setting up Paths --->
const LOG_FILE_PATH = path.join(__dirname, 'logfile.log');
const app = express();

// Serve the client HTML ---->
app.get('/log', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

// Create an HTTP server to handle express app
const server = http.createServer(app);

// Set up WebSocket server to listen on same server
const wss = new WebSocket.Server({ server });

// Function to send the last 10 lines
function sendLast10Lines(ws) {
    fs.stat(LOG_FILE_PATH, (err, stats) => {
        if (err) {
            console.error('Error getting file stats:', err);
            // In a real app, you might want to send an error to the client
            if (ws.readyState === WebSocket.OPEN) {
                ws.send('Error: Could not read log file.');
            }
            return;
        }

        const fileSize = stats.size;
        const chunkSize = 1024 * 16; // Read the last 16KB
        const start = Math.max(0, fileSize - chunkSize);

        const stream = fs.createReadStream(LOG_FILE_PATH, { start, end: fileSize });

        let data = '';
        stream.on('data', chunk => {
            data += chunk;
        });

        stream.on('end', () => {
            const lines = data.trim().split('\n');
            // Ensure we don't send more than the last 10 lines
            const last10Lines = lines.slice(-10).join('\n');
             if (ws.readyState === WebSocket.OPEN) {
                ws.send(last10Lines);
             }
        });

        stream.on('error', (err) => {
            console.error('Error reading log file:', err);
        });
    });
}

// Watch the log file for real-time updates
function watchLogFile(ws) {
    fs.watchFile(LOG_FILE_PATH, { interval: 1000 }, (curr, prev) => {
        if (curr.size > prev.size) {
            // New data appended, read only the new part
            const stream = fs.createReadStream(LOG_FILE_PATH, { start: prev.size, end: curr.size });

            stream.on('data', chunk => {
                ws.send(chunk.toString());
            });

            stream.on('error', (err) => {
                console.error('Error reading log file:', err);
            });
        }
    });
}

// Handle WebSocket connections
wss.on('connection', (ws) => {
    // Send the last 10 lines when a new client connects
    sendLast10Lines(ws);

    // Watch for real-time updates
    watchLogFile(ws);

    // ws.on('close', () => {
    //     fs.unwatchFile(LOG_FILE_PATH);
    // });
});
// --- This is the key change for testability ---
// Only start the server if the file is executed directly
if (require.main === module) {
    server.listen(8080, () => {
        console.log('Server listening on http://localhost:8080/log');
    });
}

// Export the functions and server for testing purposes
module.exports = {
    server,
    wss,
    sendLast10Lines,
    watchLogFile,
    LOG_FILE_PATH
};
