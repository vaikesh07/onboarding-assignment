Real-Time Log File Watcher
This project implements a log watching solution similar to the tail -f command in UNIX. It consists of a Node.js server that monitors a local log file for changes and a web-based client that displays these updates in real-time without requiring a page refresh.

Features
Real-Time Updates: The web client uses WebSockets to receive log updates instantly as they happen.

Efficient Data Transfer: The server only sends the newly appended lines to the client, not the entire file.

Initial Context: When a client first connects, it receives the last 10 lines of the log file to provide immediate context.

Memory Efficient: The server does not read the entire log file into memory to fetch the initial lines.

Unit Tested: The server-side logic is verified with unit tests using Mocha, Chai, and Sinon.

Prerequisites
Before you begin, ensure you have the following installed on your system:

Node.js (which includes npm)

Setup and Installation
Clone the repository or download the files into a new directory on your local machine.

Navigate to the project directory in your terminal:

cd /path/to/your/project

Create a log file to be monitored. The server expects a file named logfile.log in the root directory.

touch logfile.log

Install the required dependencies by running the following command. This will install express and ws which are needed to run the application.

npm install

Install the development dependencies required for testing. This will install mocha, chai, and sinon.

npm install mocha chai sinon --save-dev

Update package.json scripts: Ensure your package.json file has the start and test scripts defined correctly.

"scripts": {
  "start": "node server.js",
  "test": "mocha"
},

Running the Application
Start the server by running the following command from the project's root directory:

npm start

You should see a confirmation message in your console:
Server listening on http://localhost:8080/log

Open the web client by navigating to the following URL in your web browser:
http://localhost:8080/log

Simulate log updates. To see the real-time functionality, open a separate terminal window and append lines to the logfile.log file. Each time you run the command, the new line will appear in your browser.

echo "This is a new log entry at $(date)" >> logfile.log

Running the Unit Tests
The project includes unit tests for the server-side logic to ensure reliability. The tests cover sending the initial log lines and watching for file changes.

To run the tests, execute the following command from the project's root directory:

npm test

Mocha will run the tests located in the test/ directory and output the results to your console. You should see all tests passing.

File Structure
.
├── node_modules/       # Project dependencies
├── test/
│   └── server.test.js  # Unit tests for the server
├── index.html          # The front-end client page
├── logfile.log         # The log file being monitored
├── package.json        # Project metadata and dependencies
├── package-lock.json   # Exact dependency versions
└── server.js           # The Node.js server application
