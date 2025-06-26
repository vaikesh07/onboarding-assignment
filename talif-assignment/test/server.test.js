const { expect } = require('chai');
const sinon = require('sinon');
const { Readable } = require('stream');
const fs = require('fs');

// Import the functions to be tested
const { sendLast10Lines, watchLogFile } = require('../server');

// A mock WebSocket object for testing
class MockWebSocket {
    constructor() {
        this.readyState = 1; // Corresponds to WebSocket.OPEN
        this.send = sinon.spy();
        // --- FIX 1: Add a mock 'on' method ---
        // The watchLogFile function calls ws.on('close', ...), so our mock needs it.
        // It doesn't need to do anything for this test, it just needs to exist.
        this.on = sinon.spy();
    }
}


describe('Log Watcher Server Logic', () => {

    afterEach(() => {
        sinon.restore();
    });

    describe('sendLast10Lines()', () => {
        it('should read a file and send only the last 10 lines', (done) => {
            const mockWs = new MockWebSocket();
            const logContent = Array.from({ length: 15 }, (_, i) => `Line ${i + 1}`).join('\n');
            const expectedSentContent = Array.from({ length: 10 }, (_, i) => `Line ${i + 6}`).join('\n');
            const readableStream = Readable.from(logContent);
            const stats = { size: logContent.length };

            sinon.stub(fs, 'stat').callsFake((path, callback) => {
                callback(null, stats);
            });
            sinon.stub(fs, 'createReadStream').returns(readableStream);

            sendLast10Lines(mockWs);

            readableStream.on('end', () => {
                try {
                    expect(mockWs.send.calledOnce).to.be.true;
                    expect(mockWs.send.firstCall.args[0]).to.equal(expectedSentContent);
                    done();
                } catch (error) {
                    done(error);
                }
            });
        });

        it('should handle file read errors gracefully', (done) => {
             const mockWs = new MockWebSocket();
             const fakeError = new Error('File not found');
             sinon.stub(fs, 'stat').callsFake((path, callback) => {
                 callback(fakeError, null);
             });
             sendLast10Lines(mockWs);
             setTimeout(() => {
                 expect(mockWs.send.calledOnceWith('Error: Could not read log file.')).to.be.true;
                 done();
             }, 10);
        });
    });
});
