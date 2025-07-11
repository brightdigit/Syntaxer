#!/bin/bash

echo "🚀 Syntaxer Performance Benchmark"
echo "================================"
echo

# Build if needed
if [ ! -f ".build/release/syntaxer" ]; then
    echo "Building Syntaxer..."
    swift build -c release
fi

# Test file
TEST_FILE="test_performance.swift"

echo "📝 Test DSL file: $TEST_FILE"
echo

# Cold start (no cache, no template)
echo "🧊 Cold Start (no optimizations):"
time .build/release/syntaxer generate "$TEST_FILE" --no-cache --no-template > /dev/null

echo
echo "🔧 Preparing optimizations..."
.build/release/syntaxer prepare > /dev/null 2>&1

echo
echo "⚡ Warm Start (with template, no cache):"
time .build/release/syntaxer generate "$TEST_FILE" --no-cache > /dev/null

echo
echo "🚀 Hot Start (with template and cache):"
time .build/release/syntaxer generate "$TEST_FILE" > /dev/null

echo
echo "🔥 Cache Hit (second run):"
time .build/release/syntaxer generate "$TEST_FILE" > /dev/null

echo
echo "📊 Summary:"
echo "- Cold start: Full compilation from scratch"
echo "- Warm start: Using pre-built template"
echo "- Hot start: Template + result caching"
echo "- Cache hit: Direct cache retrieval"