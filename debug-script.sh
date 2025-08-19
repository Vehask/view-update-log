#!/bin/bash

# Simple debug script to test the core functionality

LOG_FILE="/var/log/update-logs/update.log"

# Enhanced timestamp parsing function to test both 12-hour and 24-hour formats
parse_timestamp() {
    local line="$1"
    local timestamp
    
    echo "Testing line: $line"
    
    # Try to extract timestamp from update log section headers
    # Support both 12-hour and 24-hour formats with various timezones
    
    # Format 1: ==== Day Mon DD HH:MM:SS AM/PM TIMEZONE YYYY ====  (12-hour)
    if [[ "$line" =~ ^=+[[:space:]]*([A-Za-z]{3}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[AP]M[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*=+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
        echo "  Found 12-hour format (===): $timestamp"
    # Format 2: ==== Day Mon DD HH:MM:SS TIMEZONE YYYY ====  (24-hour)
    elif [[ "$line" =~ ^=+[[:space:]]*([A-Za-z]{3}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*=+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
        echo "  Found 24-hour format (===): $timestamp"
    # Format 3: ########## Day Mon DD HH:MM:SS AM/PM TIMEZONE YYYY ##########  (12-hour)
    elif [[ "$line" =~ ^#+[[:space:]]*([A-Za-z]{3}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[AP]M[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*#+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
        echo "  Found 12-hour format (###): $timestamp"
    # Format 4: ########## Day Mon DD HH:MM:SS TIMEZONE YYYY ##########  (24-hour)
    elif [[ "$line" =~ ^#+[[:space:]]*([A-Za-z]{3}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*#+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
        echo "  Found 24-hour format (###): $timestamp"
    else
        echo "  No timestamp header found"
        return 1
    fi
    
    # Now parse the extracted timestamp
    if [[ "$timestamp" =~ ^[A-Za-z]{3}[[:space:]]+ ]]; then
        # Parse both 12-hour and 24-hour formats
        local month day time timezone year ampm=""
        
        # Try 12-hour format first: "Thu Jul 17 05:00:01 AM CEST 2025"
        if [[ "$timestamp" =~ ^[A-Za-z]{3}[[:space:]]+([A-Za-z]{3})[[:space:]]+([0-9]{1,2})[[:space:]]+([0-9]{2}:[0-9]{2}:[0-9]{2})[[:space:]]+([AP]M)[[:space:]]+([A-Za-z0-9+/-]{2,5})[[:space:]]+([0-9]{4}) ]]; then
            month="${BASH_REMATCH[1]}"
            day="${BASH_REMATCH[2]}"
            time="${BASH_REMATCH[3]}"
            ampm="${BASH_REMATCH[4]}"
            timezone="${BASH_REMATCH[5]}"
            year="${BASH_REMATCH[6]}"
            
            echo "  12-hour components: Month=$month, Day=$day, Time=$time, AM/PM=$ampm, TZ=$timezone, Year=$year"
            
            # Create a parseable format: "Jul 17 05:00:01 AM 2025"
            local parseable_timestamp="$month $day $time $ampm $year"
            echo "  Parsing as: '$parseable_timestamp'"
            
        # Try 24-hour format: "Thu Jul 17 17:00:01 CEST 2025"
        elif [[ "$timestamp" =~ ^[A-Za-z]{3}[[:space:]]+([A-Za-z]{3})[[:space:]]+([0-9]{1,2})[[:space:]]+([0-9]{2}:[0-9]{2}:[0-9]{2})[[:space:]]+([A-Za-z0-9+/-]{2,5})[[:space:]]+([0-9]{4}) ]]; then
            month="${BASH_REMATCH[1]}"
            day="${BASH_REMATCH[2]}"
            time="${BASH_REMATCH[3]}"
            timezone="${BASH_REMATCH[4]}"
            year="${BASH_REMATCH[5]}"
            
            echo "  24-hour components: Month=$month, Day=$day, Time=$time, TZ=$timezone, Year=$year"
            
            # Create a parseable format for 24-hour: "Jul 17 17:00:01 2025"
            local parseable_timestamp="$month $day $time $year"
            echo "  Parsing as: '$parseable_timestamp'"
            
        else
            echo "  Failed to extract components"
            return 1
        fi
        
        # Parse with date command
        local unix_timestamp
        unix_timestamp=$(date -d "$parseable_timestamp" +%s 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            echo "  Success! Unix timestamp: $unix_timestamp"
            echo "  Human readable: $(date -d "@$unix_timestamp")"
            return 0
        else
            echo "  Failed to parse with date command"
            return 1
        fi
    else
        echo "  Not a standard log header format"
        return 1
    fi
}

echo "=== Debug Script for Update Log Viewer ==="
echo

# Test current time calculations
echo "Current time: $(date)"
current_timestamp=$(date +%s)
echo "Current timestamp: $current_timestamp"

# Calculate 24 hours ago
cutoff_timestamp=$(date -d "24 hours ago" +%s)
echo "24 hours ago: $(date -d "@$cutoff_timestamp") (timestamp: $cutoff_timestamp)"
echo

# Test sample timestamp lines
echo "=== Testing timestamp parsing ==="

echo "Test 1 - 12-hour format with CEST:"
parse_timestamp "==== Thu Jul 17 05:00:01 AM CEST 2025 ===="
echo

echo "Test 2 - 12-hour format with ### headers:"
parse_timestamp "########## Wed Jul 23 05:00:01 AM CEST 2025 ##########"
echo

echo "Test 3 - 24-hour format with UTC:"
parse_timestamp "==== Thu Jul 17 17:00:01 UTC 2025 ===="
echo

echo "Test 4 - 24-hour format with CET:"
parse_timestamp "########## Wed Jul 23 14:30:15 CET 2025 ##########"
echo

echo "Test 5 - 12-hour format with EST:"
parse_timestamp "==== Fri Jul 18 09:15:30 PM EST 2025 ===="
echo

echo "Test 6 - 24-hour format with +0200:"
parse_timestamp "########## Sat Jul 19 22:45:00 +0200 2025 ##########"
echo

echo "Test 7 - 12-hour format with GMT:"
parse_timestamp "==== Sun Jul 20 11:20:45 AM GMT 2025 ===="
echo

# Check if log file exists
if [[ -f "$LOG_FILE" ]]; then
    echo "=== Checking actual log file ==="
    echo "Log file exists: $LOG_FILE"
    echo "File size: $(wc -l < "$LOG_FILE") lines"
    echo
    
    echo "First 10 lines:"
    head -10 "$LOG_FILE"
    echo
    
    echo "=== Looking for timestamp headers in log ==="
    grep -n "===\|###" "$LOG_FILE" | head -5
else
    echo "Log file not found: $LOG_FILE"
fi