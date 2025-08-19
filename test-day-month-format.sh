#!/bin/bash

# Test script to verify Day-Month format parsing
echo "Testing timestamp parsing for Day-Month format..."

# Test the specific format from the user's image
test_line="########## Wed 23 Jul 05:00:01 CEST 2025 ##########"

echo "Testing line: $test_line"
echo ""

# Extract the parse_log_timestamp function logic
if [[ "$test_line" =~ ^#+[[:space:]]*([A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*#+$ ]]; then
    timestamp="${BASH_REMATCH[1]}"
    echo "✅ Regex matched successfully!"
    echo "Extracted timestamp: '$timestamp'"
    
    # Test parsing the Day-Month format: "Wed 23 Jul 05:00:01 CEST 2025"
    if [[ "$timestamp" =~ ^[A-Za-z]{3}[[:space:]]+([0-9]{1,2})[[:space:]]+([A-Za-z]{3})[[:space:]]+([0-9]{2}:[0-9]{2}:[0-9]{2})[[:space:]]+([A-Za-z0-9+/-]{2,5})[[:space:]]+([0-9]{4}) ]]; then
        day="${BASH_REMATCH[1]}"
        month="${BASH_REMATCH[2]}"
        time="${BASH_REMATCH[3]}"
        timezone="${BASH_REMATCH[4]}"
        year="${BASH_REMATCH[5]}"
        
        echo "✅ Day-Month 24-hour format parsing successful!"
        echo "  Day: $day"
        echo "  Month: $month"
        echo "  Time: $time"
        echo "  Timezone: $timezone"
        echo "  Year: $year"
        
        # Create parseable format: "Jul 23 05:00:01 2025"
        parseable_timestamp="$month $day $time $year"
        echo "  Parseable format: '$parseable_timestamp'"
        
        # Test with date command
        unix_timestamp=$(date -d "$parseable_timestamp" +%s 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            echo "✅ Successfully converted to Unix timestamp: $unix_timestamp"
            readable_date=$(date -d "@$unix_timestamp" '+%Y-%m-%d %H:%M:%S %Z')
            echo "  Readable date: $readable_date"
        else
            echo "❌ Failed to convert to Unix timestamp"
        fi
    else
        echo "❌ Day-Month format parsing failed"
    fi
else
    echo "❌ Regex did not match the test line"
fi

echo ""
echo "Testing comparison formats:"

# Test other formats for comparison
formats=(
    "==== Thu Jul 17 05:00:01 AM CEST 2025 ====" 
    "==== Thu Jul 17 17:00:01 CEST 2025 ====" 
    "########## Wed 23 Jul 17:00:01 CEST 2025 ##########"
)

for format in "${formats[@]}"; do
    echo "Format: $format"
    if [[ "$format" =~ ^[=#+]+[[:space:]]*([A-Za-z]{3}[[:space:]]+[0-9A-Za-z]{1,3}[[:space:]]+[0-9A-Za-z]{1,3}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}.*[0-9]{4})[[:space:]]*[=#+]+$ ]]; then
        echo "  ✅ Matches general pattern: '${BASH_REMATCH[1]}'"
    else
        echo "  ❌ Does not match general pattern"
    fi
    echo ""
done