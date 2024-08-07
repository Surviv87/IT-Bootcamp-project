#!/bin/sh
sleep 10
URL="http:/localhost:3000"

HTTP_RESPONSE=$(curl -s -o /dev/null -w '%{http_code}' "$URL")
  
if [ "$HTTP_RESPONSE" -eq 200 ]; then  
    echo "Success: The URL '$URL' is reachable!"
else  
    echo "Error: The URL '$URL' returned status code $HTTP_RESPONSE."
    exit 1  
fi