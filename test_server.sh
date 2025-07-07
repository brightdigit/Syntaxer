#!/bin/bash

# Start the server
echo "Starting server..."
swift run syntaxer-api &
SERVER_PID=$!

# Wait for server to start
sleep 3

# Test the server
echo "Testing server..."
curl -X POST http://localhost:8080/api/generate \
     -H "Content-Type: application/json" \
     -d '{"dslCode": "Function(\"hello\") { Literal.string(\"Hello, World!\") }"}'

echo ""
echo "Killing server..."
kill $SERVER_PID

# Wait a moment for it to die
sleep 1