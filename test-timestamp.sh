#!/bin/bash

# Test script to debug timestamp parsing

# Test the timestamp parsing function
parse_log_timestamp() {
    local line="$1"
    local timestamp
    
    echo "Testing line: $line"
    
    # Try to extract timestamp from update log section headers
    # Format 1: ==== Day Mon DD HH:MM:SS AM/PM TIMEZONE YYYY ====
    if [[ "$line" =~ ^====.*([A-Za-z]{3}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[AP]M[[:space:]]+[A-Z]{3,4}[[:space:]]+[0-9]{4}).*====$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
        echo "Found format 1 timestamp: $timestamp"
    # Format 2: ########## Day Mon DD HH:MM:SS AM/PM TIMEZONE YYYY ##########
    elif [[ "$line" =~ ^#+.*([A-Za-z]{3}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[AP]M[[:space:]]+[A-Z]{3,4}[[:space:]]+[0-9]{4}).*#+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
        echo "Found format 2 timestamp: $timestamp"
    else
        echo "No timestamp found"
        return 1
    fi
    
    # Convert to Unix timestamp
    # Handle the special format from update log headers
    if [[ "$timestamp" =~ ^[A-Za-z]{3}[[:space:]]+ ]]; then
        # Convert format like "Thu Jul 17 05:00:01 AM CEST 2025" to a parseable format
        # Remove the day of week and timezone for simpler parsing
        local simplified_timestamp
        simplified_timestamp=$(echo "$timestamp" | sed -E 's/^[A-Za-z]{3}[[:space:]]+([A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[AP]M)[[:space:]]+[A-Z]{3,4}[[:space:]]+([0-9]{4})$/\1 \2/')
        
        echo "Simplified timestamp: $simplified_timestamp"
        
        # Parse with date command
        local unix_timestamp
        unix_timestamp=$(date -d "$simplified_timestamp" +%s 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            echo "Unix timestamp: $unix_timestamp"
            echo "Human readable: $(date -d "@$unix_timestamp")"
            echo "$unix_timestamp"
        else
            echo "Failed to parse simplified timestamp"
            return 1
        fi
    else
        # Standard format, parse directly
        local unix_timestamp
        unix_timestamp=$(date -d "$timestamp" +%s 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            echo "Unix timestamp: $unix_timestamp"
            echo "$unix_timestamp"
        else
            echo "Failed to parse timestamp"
            return 1
        fi
    fi
}

# Test cases
echo "=== Testing timestamp parsing ==="
echo

echo "Test 1:"
parse_log_timestamp "==== Thu Jul 17 05:00:01 AM CEST 2025 ===="
echo

echo "Test 2:"
parse_log_timestamp "########## Wed Jul 23 05:00:01 AM CEST 2025 ##########"
echo

echo "Test 3:"
parse_log_timestamp "Hit:1 http://deb.debian.org/debian bookworm InRelease"
echo

# Test current time calculation
echo "=== Time calculations ==="
current_time=$(date +%s)
echo "Current time: $current_time ($(date -d "@$current_time"))"

# 24 hours ago
cutoff_24h=$(date -d "24 hours ago" +%s)
echo "24 hours ago: $cutoff_24h ($(date -d "@$cutoff_24h"))"

# Test if July 17 is within last 24 hours
july_17=$(date -d "Jul 17 05:00:01 AM 2025" +%s 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "July 17 timestamp: $july_17 ($(date -d "@$july_17"))"
    if [[ $july_17 -ge $cutoff_24h ]]; then
        echo "July 17 is within last 24 hours"
    else
        echo "July 17 is NOT within last 24 hours"
    fi
else
    echo "Failed to parse July 17 date"
fi

# Test if July 23 is within last 24 hours
july_23=$(date -d "Jul 23 05:00:01 AM 2025" +%s 2>/dev/null)
if [[ $? -eq 0 ]]; then
    echo "July 23 timestamp: $july_23 ($(date -d "@$july_23"))"
    if [[ $july_23 -ge $cutoff_24h ]]; then
        echo "July 23 is within last 24 hours"
    else
        echo "July 23 is NOT within last 24 hours"
    fi
else
    echo "Failed to parse July 23 date"
fi