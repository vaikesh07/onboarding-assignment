const express = require('express');
const http = require('http');
const WebSocket = require('ws');
const fs = require('fs');
const path = require('path');

const LOG_FILE_PATH = path.join(__dirname, 'logfile.log');
const app = express();

app.get('/log', (req, res) => {
    res.sendFile(path.join(__dirname, 'index.html'));
});

const server = http.createServer(app);
const wss = new WebSocket.Server({ server });

/**
 * Reads the last N lines from a file without reading the entire file into memory.
 * It reads the file backwards character-by-character (in chunks for efficiency)
 * and builds the lines until the desired count is reached.
 *
 * @param {WebSocket} ws The WebSocket client to send data to.
 * @param {number} lineCount The number of lines to read from the end of the file.
 */
async function sendLastNLines(ws, lineCount) {
    try {
        const fileHandle = await fs.promises.open(LOG_FILE_PATH, 'r');
        const stats = await fileHandle.stat();
        let fileSize = stats.size;

        if (fileSize === 0) {
            if (ws.readyState === WebSocket.OPEN) ws.send('');
            await fileHandle.close();
            return;
        }

        const bufferSize = 1024; // Read in 1KB chunks for performance
        const buffer = Buffer.alloc(bufferSize);
        let filePosition = fileSize;
        let currentLine = '';
        const lines = [];

        while (filePosition > 0 && lines.length < lineCount) {
            const readLength = Math.min(bufferSize, filePosition);
            filePosition -= readLength;

            await fileHandle.read(buffer, 0, readLength, filePosition);
            const chunk = buffer.toString('utf-8', 0, readLength);

            for (let i = chunk.length - 1; i >= 0; i--) {
                const char = chunk[i];
                if (char === '\n') {
                    if (currentLine) {
                        lines.unshift(currentLine);
                        currentLine = '';
                    }
                    if (lines.length >= lineCount) break;
                } else {
                    currentLine = char + currentLine;
                }
            }
        }

        if (currentLine && lines.length < lineCount) {
            lines.unshift(currentLine);
        }

        if (ws.readyState === WebSocket.OPEN) {
            ws.send(lines.join('\n'));
        }

        await fileHandle.close();

    } catch (err) {
        console.error('Error reading log file:', err);
        if (ws.readyState === WebSocket.OPEN) {
            ws.send('Error: Could not read log file.');
        }
    }
}


/**
 * Sets up a single, global watcher for the log file. This watcher maintains a
 * reading position for each individual client and sends them tailored updates.
 */
function setupGlobalFileWatcher() {
    fs.watch(LOG_FILE_PATH, (eventType) => {
        if (eventType === 'change') {
            fs.stat(LOG_FILE_PATH, (err, stats) => {
                if (err) {
                    console.error("Error stating file during watch:", err);
                    return;
                }
                const newSize = stats.size;

                // Iterate over each connected client
                wss.clients.forEach(client => {
                    if (client.readyState === WebSocket.OPEN) {
                        // Ensure the client has a lastReadPosition, default to 0 if not
                        if (typeof client.lastReadPosition === 'undefined') {
                            client.lastReadPosition = 0;
                        }

                        // If the file has grown, send the new data to this specific client
                        if (newSize > client.lastReadPosition) {
                            const stream = fs.createReadStream(LOG_FILE_PATH, {
                                start: client.lastReadPosition,
                                end: newSize
                            });

                            stream.on('data', (chunk) => {
                                client.send(chunk.toString());
                            });

                            // Update this client's read position once the data is sent
                            client.lastReadPosition = newSize;

                        } else if (newSize < client.lastReadPosition) {
                            // Handle file truncation: reset the client's position
                            client.lastReadPosition = newSize;
                        }
                    }
                });
            });
        }
    });

    console.log(`Now watching ${LOG_FILE_PATH} for changes.`);
}


// Handle WebSocket connections
wss.on('connection', (ws) => {
    console.log('Client connected');
    // Send the last 10 lines for initial context
    sendLastNLines(ws, 10);

    // Initialize the reading position for this specific client
    fs.stat(LOG_FILE_PATH, (err, stats) => {
        if (!err) {
            ws.lastReadPosition = stats.size;
        } else {
            // If file doesn't exist, start from the beginning
            ws.lastReadPosition = 0;
        }
    });

    ws.on('close', () => {
        console.log('Client disconnected');
    });
});

// --- Start the server and the global watcher ---
if (require.main === module) {
    server.listen(8080, () => {
        console.log('Server listening on http://localhost:8080/log');
        // Start the single file watcher when the server starts
        setupGlobalFileWatcher();
    });
}

// Export the functions and server for testing purposes
module.exports = {
    server,
    wss,
    sendLastNLines,
    LOG_FILE_PATH
};
