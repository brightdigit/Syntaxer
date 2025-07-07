#!/bin/bash

# Run server in foreground to see all output
echo "Starting server with debug output..."
swift run syntaxer-api &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Test the server
echo "Testing server..."
curl -X POST http://localhost:8080/api/generate \
     -H "Content-Type: application/json" \
     -d '{"dslCode": "Function(\"hello\") { Literal.string(\"Hello, World!\") }", "debug": true}' 2>&1

echo ""
echo "Killing server..."
kill $SERVER_PID 2>/dev/null

# Show any server output that was captured
wait $SERVER_PID 2>/dev/null