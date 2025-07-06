#!/bin/bash
# This script checks if the server is running

echo "Checking if Phoenix server is running..."
curl -I http://localhost:4000
echo ""
echo "Checking if we can get content from the server..."
curl http://localhost:4000 -o response.html
echo "Response saved to response.html"