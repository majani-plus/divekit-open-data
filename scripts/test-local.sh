#!/bin/bash

# Local Testing Script for GitHub Pages Setup
# This script starts a local web server to test your site before deploying

set -e

echo "Dive Kit Open - Local Testing Script"
echo "========================================"
echo ""

# Check if we're in the right directory
if [ ! -f "README.md" ] || [ ! -f "CNAME" ]; then
    echo "❌ Error: Please run this script from the repository root"
    exit 1
fi

echo "✅ Found required files"
echo ""

# Find an available port
PORT=8000
while lsof -Pi :$PORT -sTCP:LISTEN -t >/dev/null 2>&1 ; do
    echo "⚠️  Port $PORT is in use, trying next port..."
    PORT=$((PORT + 1))
done

echo "📡 Starting local server on port $PORT..."
echo ""

# Run Server
echo "📦 Using bunx http-server"
echo ""
echo "🚀 Server running at: http://localhost:$PORT"
echo ""
echo "📋 Test these URLs:"
echo "   • http://localhost:$PORT/ (homepage)"
echo "   • http://localhost:$PORT/schemas/certifications/dive-certifications.schema.v1.0.0.json"
echo "   • http://localhost:$PORT/404.html (404 page)"
echo ""
echo "Press Ctrl+C to stop the server"
echo ""
bunx --yes http-server -p $PORT
