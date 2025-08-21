#!/bin/bash

# ╭─────────────────────────────────────────────────────────────╮
# │                  Proxmox Update Log Viewer                  │
# │                                                             │
# │  Description: Display update log entries with flexible      │
# │               time ranges, colored output, and line numbers │
# │                                                             │
# │  Usage: ./view-update-log.sh [OPTIONS]                      │
# │  Options: [Global Variables - Line 31]                      │
# ╰─────────────────────────────────────────────────────────────╯

# Default configuration
readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/var/log/update-logs/update.log"
readonly DEFAULT_HOURS=24

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly GRAY='\033[0;37m'
readonly ORANGE='\033[0;33m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# Global variables
HOURS=""
DAYS=""
MINUTES=""
SINCE=""
UNTIL=""
LAST_PULL=""
NO_COLOR=false
NO_LINE_NUMBERS=false
QUIET=false
SHOW_HELP=false

# Global variable to store pull days for filtering
PULL_DAYS_FILTER=()

# Function to display usage information
display_usage() {
    cat << EOF
${BOLD}${CYAN}Proxmox Update Log Viewer${NC}

${BOLD}DESCRIPTION:${NC}
    Display update log entries from /var/log/update-logs/update.log
    with flexible time filtering, colored output, and line numbers.

${BOLD}USAGE:${NC}
    $SCRIPT_NAME [OPTIONS]

${BOLD}TIME RANGE OPTIONS:${NC}
    --hours <number>        Show entries from the past N hours (default: 24)
    --days <number>         Show entries from the past N days
    --minutes <number>      Show entries from the past N minutes
    --since <timestamp>     Show entries since specific date/time
    --until <timestamp>     Show entries until specific date/time
    --last-pull [number]    Show entries from days with Docker updates (default: 1, last update day)

${BOLD}DISPLAY OPTIONS:${NC}
    --no-color             Disable colored output
    --no-line-numbers      Disable line numbering
    --quiet                Suppress header and summary
    --help                 Display this help message

${BOLD}TIMESTAMP FORMATS:${NC}
    Accepted formats for --since and --until:
    - "YYYY-MM-DD HH:MM:SS"
    - "YYYY-MM-DD"
    - "HH:MM:SS" (today's date)

${BOLD}EXAMPLES:${NC}
    $SCRIPT_NAME                           # Last 24 hours (default)
    $SCRIPT_NAME --hours 12                # Last 12 hours
    $SCRIPT_NAME --days 3                  # Last 3 days
    $SCRIPT_NAME --minutes 30              # Last 30 minutes
    $SCRIPT_NAME --last-pull               # Last day with Docker updates
    $SCRIPT_NAME --last-pull 3             # Last 3 days with Docker updates
    $SCRIPT_NAME --since "2025-01-20 10:00:00"
    $SCRIPT_NAME --until "2025-01-23 12:00:00"
    $SCRIPT_NAME --days 1 --no-color      # Last day without colors
    $SCRIPT_NAME --hours 6 --quiet        # Last 6 hours, minimal output

${BOLD}EXIT CODES:${NC}
    0    Success
    1    General error
    2    Invalid arguments
    3    Log file not found or not readable

EOF
}

# Function to print colored output
print_color() {
    local color="$1"
    local message="$2"
    if [[ "$NO_COLOR" == true ]]; then
        echo -e "$message"
    else
        echo -e "${color}${message}${NC}"
    fi
}

# Function to print error messages
print_error() {
    print_color "$RED" "ERROR: $1" >&2
}

# Function to print warning messages
print_warning() {
    print_color "$YELLOW" "WARNING: $1" >&2
}

# Function to print info messages
print_info() {
    print_color "$BLUE" "INFO: $1"
}

# Function to validate arguments
validate_arguments() {
    local time_options=0
    
    # Count time options
    [[ -n "$HOURS" ]] && ((time_options++))
    [[ -n "$DAYS" ]] && ((time_options++))
    [[ -n "$MINUTES" ]] && ((time_options++))
    [[ -n "$SINCE" || -n "$UNTIL" ]] && ((time_options++))
    [[ -n "$LAST_PULL" ]] && ((time_options++))
    
    # Check for conflicting time options
    if [[ $time_options -gt 1 ]]; then
        print_error "Cannot combine multiple time range options"
        print_error "Use either --hours, --days, --minutes, --since/--until, or --last-pull"
        return 2
    fi
    
    # Validate numeric values
    if [[ -n "$HOURS" ]] && ! [[ "$HOURS" =~ ^[0-9]+$ ]]; then
        print_error "Hours must be a positive integer"
        return 2
    fi
    
    if [[ -n "$DAYS" ]] && ! [[ "$DAYS" =~ ^[0-9]+$ ]]; then
        print_error "Days must be a positive integer"
        return 2
    fi
    
    if [[ -n "$MINUTES" ]] && ! [[ "$MINUTES" =~ ^[0-9]+$ ]]; then
        print_error "Minutes must be a positive integer"
        return 2
    fi
    
    if [[ -n "$LAST_PULL" ]] && ! [[ "$LAST_PULL" =~ ^[0-9]+$ ]]; then
        print_error "Last-pull count must be a positive integer"
        return 2
    fi
    
    # Validate timestamp formats
    if [[ -n "$SINCE" ]] && ! validate_timestamp "$SINCE"; then
        print_error "Invalid --since timestamp format"
        return 2
    fi
    
    if [[ -n "$UNTIL" ]] && ! validate_timestamp "$UNTIL"; then
        print_error "Invalid --until timestamp format"
        return 2
    fi
    
    return 0
}

# Function to validate timestamp format
validate_timestamp() {
    local timestamp="$1"
    
    # Try to parse the timestamp with date command
    if date -d "$timestamp" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to parse command-line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --hours)
                HOURS="$2"
                shift 2
                ;;
            --days)
                DAYS="$2"
                shift 2
                ;;
            --minutes)
                MINUTES="$2"
                shift 2
                ;;
            --since)
                SINCE="$2"
                shift 2
                ;;
            --until)
                UNTIL="$2"
                shift 2
                ;;
            --last-pull)
                # Check if next argument is a number or another option
                if [[ $# -gt 1 && "$2" =~ ^[0-9]+$ ]]; then
                    LAST_PULL="$2"
                    shift 2
                else
                    LAST_PULL="1"  # Default to 1 if no number provided
                    shift
                fi
                ;;
            --no-color)
                NO_COLOR=true
                shift
                ;;
            --no-line-numbers)
                NO_LINE_NUMBERS=true
                shift
                ;;
            --quiet)
                QUIET=true
                shift
                ;;
            --help|-h)
                SHOW_HELP=true
                shift
                ;;
            *)
                print_error "Unknown option: $1"
                print_error "Use --help for usage information"
                return 2
                ;;
        esac
    done
    
    return 0
}

# Function to calculate time cutoff
calculate_time_cutoff() {
    local cutoff_timestamp
    
    if [[ -n "$LAST_PULL" ]]; then
        # Handle --last-pull option
        local pull_days
        mapfile -t pull_days < <(find_pull_days "$LAST_PULL")
        
        
        if [[ ${#pull_days[@]} -eq 0 ]]; then
            print_error "No days with Docker pulls found in log file"
            return 1
        fi
        
        # Store pull days for filtering in process_log_entries
        PULL_DAYS_FILTER=("${pull_days[@]}")
        
        
        # Get the oldest day from our selection (last element since they're sorted newest first)
        local oldest_day="${pull_days[-1]}"
        
        # Convert to timestamp at start of day (00:00:00)
        cutoff_timestamp=$(date -d "$oldest_day 00:00:00" +%s 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            print_error "Failed to parse oldest pull day: $oldest_day"
            return 1
        fi
        echo "$cutoff_timestamp"
        return 0
    fi
    
    if [[ -n "$SINCE" ]]; then
        cutoff_timestamp=$(date -d "$SINCE" +%s 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            print_error "Failed to parse --since timestamp"
            return 1
        fi
        echo "$cutoff_timestamp"
        return 0
    fi
    
    if [[ -n "$UNTIL" ]]; then
        # For --until, we need to handle this separately in the main logic
        echo "0"
        return 0
    fi
    
    local time_value
    local time_unit
    
    if [[ -n "$MINUTES" ]]; then
        time_value="$MINUTES"
        time_unit="minutes"
    elif [[ -n "$HOURS" ]]; then
        time_value="$HOURS"
        time_unit="hours"
    elif [[ -n "$DAYS" ]]; then
        time_value="$DAYS"
        time_unit="days"
    else
        time_value="$DEFAULT_HOURS"
        time_unit="hours"
    fi
    
    cutoff_timestamp=$(date -d "$time_value $time_unit ago" +%s 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        print_error "Failed to calculate time cutoff"
        return 1
    fi
    
    echo "$cutoff_timestamp"
    return 0
}

# Function to get until timestamp
get_until_timestamp() {
    if [[ -n "$UNTIL" ]]; then
        date -d "$UNTIL" +%s 2>/dev/null
    else
        date +%s  # Current time
    fi
}

# Function to find days with Docker updates
find_pull_days() {
    local count="$1"
    local pull_days=()
    local current_date=""
    local found_pull=false
    
    # Read through the log file to find days with pulls
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Check if this line is a timestamp header
        local log_timestamp
        log_timestamp=$(parse_log_timestamp "$line")
        
        if [[ $? -eq 0 ]]; then
            # Convert timestamp to date (YYYY-MM-DD format)
            local date_str
            date_str=$(date -d "@$log_timestamp" +%Y-%m-%d 2>/dev/null)
            
            if [[ $? -eq 0 ]]; then
                # If we found a pull in the previous date, add it to the array
                if [[ "$found_pull" == true && -n "$current_date" ]]; then
                    pull_days+=("$current_date")
                fi
                
                # Reset for new date
                current_date="$date_str"
                found_pull=false
            fi
        elif [[ "$line" =~ [Pp]ull\ [Cc]omplete|[Dd]ownload\ [Cc]omplete ]]; then
            # Found a pull/download complete operation in current date
            found_pull=true
        fi
        
    done < "$LOG_FILE"
    
    # Don't forget the last date if it had pulls
    if [[ "$found_pull" == true && -n "$current_date" ]]; then
        pull_days+=("$current_date")
    fi
    
    # Remove duplicates and sort in reverse order (newest first)
    local unique_days=($(printf '%s\n' "${pull_days[@]}" | sort -u -r))
    
    # Return the requested number of days
    local result_days=()
    for ((i=0; i<count && i<${#unique_days[@]}; i++)); do
        result_days+=("${unique_days[i]}")
    done
    
    # Output the days (space-separated)
    printf '%s\n' "${result_days[@]}"
}

# Function to parse log timestamp
parse_log_timestamp() {
    local line="$1"
    local timestamp
    
    # Try to extract timestamp from update log section headers
    # Support both 12-hour and 24-hour formats with various timezones
    # Handle both "Day Mon DD" and "Day DD Mon" date orderings
    # Handle optional prefix text (like "System & Docker Update")
    
    # Format 1: ==== [Optional Text] Day Mon DD HH:MM:SS AM/PM TIMEZONE YYYY ====  (12-hour, Month-Day order)
    if [[ "$line" =~ ^=+[[:space:]]*.*([A-Za-z]{3}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[AP]M[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*=+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
    # Format 2: ==== [Optional Text] Day DD Mon HH:MM:SS AM/PM TIMEZONE YYYY ====  (12-hour, Day-Month order)
    elif [[ "$line" =~ ^=+[[:space:]]*.*([A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[AP]M[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*=+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
    # Format 3: ==== [Optional Text] Day Mon DD HH:MM:SS TIMEZONE YYYY ====  (24-hour, Month-Day order)
    elif [[ "$line" =~ ^=+[[:space:]]*.*([A-Za-z]{3}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*=+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
    # Format 4: ==== [Optional Text] Day DD Mon HH:MM:SS TIMEZONE YYYY ====  (24-hour, Day-Month order)
    elif [[ "$line" =~ ^=+[[:space:]]*.*([A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*=+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
    # Format 5: ########## [Optional Text] Day Mon DD HH:MM:SS AM/PM TIMEZONE YYYY ##########  (12-hour, Month-Day order)
    elif [[ "$line" =~ ^#+[[:space:]]*.*([A-Za-z]{3}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[AP]M[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*#+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
    # Format 6: ########## [Optional Text] Day DD Mon HH:MM:SS AM/PM TIMEZONE YYYY ##########  (12-hour, Day-Month order)
    elif [[ "$line" =~ ^#+[[:space:]]*.*([A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[AP]M[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*#+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
    # Format 7: ########## [Optional Text] Day Mon DD HH:MM:SS TIMEZONE YYYY ##########  (24-hour, Month-Day order)
    elif [[ "$line" =~ ^#+[[:space:]]*.*([A-Za-z]{3}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*#+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
    # Format 8: ########## [Optional Text] Day DD Mon HH:MM:SS TIMEZONE YYYY ##########  (24-hour, Day-Month order)
    elif [[ "$line" =~ ^#+[[:space:]]*.*([A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*#+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
    # Format 9: ############## [Text] at Day Mon DD HH:MM:SS TIMEZONE YYYY ##############  (Special "at" format)
    elif [[ "$line" =~ ^#+.*[[:space:]]at[[:space:]]+([A-Za-z]{3}[[:space:]]+[A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+[0-9]{4})[[:space:]]*#+$ ]]; then
        timestamp="${BASH_REMATCH[1]}"
    # Format 10: [YYYY-MM-DD HH:MM:SS] (fallback)
    elif [[ "$line" =~ \[([0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2})\] ]]; then
        timestamp="${BASH_REMATCH[1]}"
    # Format 11: YYYY-MM-DD HH:MM:SS (fallback)
    elif [[ "$line" =~ ^([0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}) ]]; then
        timestamp="${BASH_REMATCH[1]}"
    else
        # No recognizable timestamp
        return 1
    fi
    
    # Convert to Unix timestamp
    # Handle the special format from update log headers
    if [[ "$timestamp" =~ ^[A-Za-z]{3}[[:space:]]+ ]]; then
        # Parse both 12-hour and 24-hour formats with different date orderings
        local month day time timezone year ampm=""
        
        # Try 12-hour format, Month-Day order: "Thu Jul 17 05:00:01 AM CEST 2025"
        if [[ "$timestamp" =~ ^[A-Za-z]{3}[[:space:]]+([A-Za-z]{3})[[:space:]]+([0-9]{1,2})[[:space:]]+([0-9]{2}:[0-9]{2}:[0-9]{2})[[:space:]]+([AP]M)[[:space:]]+([A-Za-z0-9+/-]{2,5})[[:space:]]+([0-9]{4}) ]]; then
            month="${BASH_REMATCH[1]}"
            day="${BASH_REMATCH[2]}"
            time="${BASH_REMATCH[3]}"
            ampm="${BASH_REMATCH[4]}"
            timezone="${BASH_REMATCH[5]}"
            year="${BASH_REMATCH[6]}"
            
            # Create a parseable format: "Jul 17 05:00:01 AM 2025"
            local parseable_timestamp="$month $day $time $ampm $year"
            
        # Try 12-hour format, Day-Month order: "Wed 23 Jul 05:00:01 AM CEST 2025"
        elif [[ "$timestamp" =~ ^[A-Za-z]{3}[[:space:]]+([0-9]{1,2})[[:space:]]+([A-Za-z]{3})[[:space:]]+([0-9]{2}:[0-9]{2}:[0-9]{2})[[:space:]]+([AP]M)[[:space:]]+([A-Za-z0-9+/-]{2,5})[[:space:]]+([0-9]{4}) ]]; then
            day="${BASH_REMATCH[1]}"
            month="${BASH_REMATCH[2]}"
            time="${BASH_REMATCH[3]}"
            ampm="${BASH_REMATCH[4]}"
            timezone="${BASH_REMATCH[5]}"
            year="${BASH_REMATCH[6]}"
            
            # Create a parseable format: "Jul 23 05:00:01 AM 2025"
            local parseable_timestamp="$month $day $time $ampm $year"
            
        # Try 24-hour format, Month-Day order: "Thu Jul 17 17:00:01 CEST 2025"
        elif [[ "$timestamp" =~ ^[A-Za-z]{3}[[:space:]]+([A-Za-z]{3})[[:space:]]+([0-9]{1,2})[[:space:]]+([0-9]{2}:[0-9]{2}:[0-9]{2})[[:space:]]+([A-Za-z0-9+/-]{2,5})[[:space:]]+([0-9]{4}) ]]; then
            month="${BASH_REMATCH[1]}"
            day="${BASH_REMATCH[2]}"
            time="${BASH_REMATCH[3]}"
            timezone="${BASH_REMATCH[4]}"
            year="${BASH_REMATCH[5]}"
            
            # Create a parseable format for 24-hour: "Jul 17 17:00:01 2025"
            local parseable_timestamp="$month $day $time $year"
            
        # Try 24-hour format, Day-Month order: "Wed 23 Jul 17:00:01 CEST 2025"
        elif [[ "$timestamp" =~ ^[A-Za-z]{3}[[:space:]]+([0-9]{1,2})[[:space:]]+([A-Za-z]{3})[[:space:]]+([0-9]{2}:[0-9]{2}:[0-9]{2})[[:space:]]+([A-Za-z0-9+/-]{2,5})[[:space:]]+([0-9]{4}) ]]; then
            day="${BASH_REMATCH[1]}"
            month="${BASH_REMATCH[2]}"
            time="${BASH_REMATCH[3]}"
            timezone="${BASH_REMATCH[4]}"
            year="${BASH_REMATCH[5]}"
            
            # Create a parseable format for 24-hour: "Jul 23 17:00:01 2025"
            local parseable_timestamp="$month $day $time $year"
            
        else
            # Fallback: try parsing as-is
            local parseable_timestamp="$timestamp"
        fi
        
        # Parse with date command
        local unix_timestamp
        unix_timestamp=$(date -d "$parseable_timestamp" +%s 2>/dev/null)
        if [[ $? -eq 0 ]]; then
            echo "$unix_timestamp"
            return 0
        else
            # Try alternative parsing methods
            # Remove timezone and try again
            local simplified_timestamp
            simplified_timestamp=$(echo "$timestamp" | sed -E 's/^[A-Za-z]{3}[[:space:]]+([A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2})([[:space:]]+[AP]M)?[[:space:]]+[A-Za-z0-9+/-]{2,5}[[:space:]]+([0-9]{4})$/\1\2 \3/')
            unix_timestamp=$(date -d "$simplified_timestamp" +%s 2>/dev/null)
            if [[ $? -eq 0 ]]; then
                echo "$unix_timestamp"
                return 0
            else
                return 1
            fi
        fi
    else
        # Standard format, parse directly
        date -d "$timestamp" +%s 2>/dev/null
    fi
}

# Function to format output line
format_output_line() {
    local line_number="$1"
    local log_line="$2"
    local formatted_line=""
    
    # Add line number if enabled
    if [[ "$NO_LINE_NUMBERS" == false ]]; then
        local line_num_str
        printf -v line_num_str "%4d" "$line_number"
        formatted_line="${GREEN}${line_num_str}${NC}  "
    fi
    
    # Special highlighting for timestamp headers (orange)
    if [[ "$log_line" =~ ^[#=]+.*[0-9]{4}.*[#=]+$ ]]; then
        formatted_line+="${ORANGE}${log_line}${NC}"
    # Special highlighting for package summary lines (yellow)
    elif [[ "$log_line" =~ [0-9]+.*upgraded.*[0-9]+.*newly.*installed.*[0-9]+.*to.*remove.*[0-9]+.*not.*upgraded ]]; then
        formatted_line+="${YELLOW}${log_line}${NC}"
    # Special highlighting for package operation descriptions (yellow)
    elif [[ "$log_line" =~ ^The\ following\ package.*automatically\ installed.*no\ longer\ required ]]; then
        formatted_line+="${YELLOW}${log_line}${NC}"
    elif [[ "$log_line" =~ ^The\ following\ NEW\ packages\ will\ be\ installed ]]; then
        formatted_line+="${YELLOW}${log_line}${NC}"
    elif [[ "$log_line" =~ ^The\ following\ packages\ will\ be\ upgraded ]]; then
        formatted_line+="${YELLOW}${log_line}${NC}"
    elif [[ "$log_line" =~ ^The\ following\ packages\ will\ be\ REMOVED ]]; then
        formatted_line+="${YELLOW}${log_line}${NC}"
    # Docker Compose specific highlighting - Yellow for pulling and starting operations
    elif [[ "$log_line" =~ [Pp]ulling|Container.*Starting ]]; then
        formatted_line+="${YELLOW}${log_line}${NC}"
    # Docker Compose specific highlighting - Green for completed operations
    elif [[ "$log_line" =~ Download\ complete|Pull\ complete|[Pp]ulled|Total\ reclaimed\ space|Container.*Running|Container.*Recreate|Container.*Started|Update\ Complete ]]; then
        formatted_line+="${GREEN}${log_line}${NC}"
    # Docker Compose specific highlighting - Red for deletion operations
    elif [[ "$log_line" =~ deleted|untagged ]]; then
        formatted_line+="${RED}${log_line}${NC}"
    # Apply colors based on log level
    elif [[ "$log_line" =~ ERROR|CRITICAL|FATAL ]]; then
        formatted_line+="${RED}${log_line}${NC}"
    elif [[ "$log_line" =~ WARNING|WARN ]]; then
        formatted_line+="${YELLOW}${log_line}${NC}"
    elif [[ "$log_line" =~ INFO ]]; then
        formatted_line+="${BLUE}${log_line}${NC}"
    elif [[ "$log_line" =~ DEBUG ]]; then
        formatted_line+="${GRAY}${log_line}${NC}"
    else
        formatted_line+="${WHITE}${log_line}${NC}"
    fi
    
    echo -e "$formatted_line"
}

# Function to display header
display_header() {
    [[ "$QUIET" == true ]] && return
    
    local time_range_text
    local from_time
    local to_time
    
    # Determine time range description
    if [[ -n "$LAST_PULL" ]]; then
        if [[ "$LAST_PULL" -eq 1 ]]; then
            time_range_text="Last day with Docker updates"
        else
            time_range_text="Last $LAST_PULL days with Docker updates"
        fi
    elif [[ -n "$SINCE" && -n "$UNTIL" ]]; then
        time_range_text="From $SINCE to $UNTIL"
    elif [[ -n "$SINCE" ]]; then
        time_range_text="Since $SINCE"
    elif [[ -n "$UNTIL" ]]; then
        time_range_text="Until $UNTIL"
    elif [[ -n "$MINUTES" ]]; then
        time_range_text="Last $MINUTES minutes"
    elif [[ -n "$HOURS" ]]; then
        time_range_text="Last $HOURS hours"
    elif [[ -n "$DAYS" ]]; then
        time_range_text="Last $DAYS days"
    else
        time_range_text="Last $DEFAULT_HOURS hours"
    fi
    
    print_color "$CYAN" "╭─────────────────────────────────────────────────────────────╮"
    print_color "$CYAN" "│ ${BOLD}Proxmox Update Log Viewer - $time_range_text${NC}${CYAN}"
    
    # Add padding to center the text
    local padding_length=$((59 - ${#time_range_text}))
    printf "${CYAN}│${NC}"
    printf "%*s" $padding_length ""
    print_color "$CYAN" "│"
    
    print_color "$CYAN" "│ Log file: $LOG_FILE"
    local file_padding=$((45 - ${#LOG_FILE}))
    printf "${CYAN}│${NC}"
    printf "%*s" $file_padding ""
    print_color "$CYAN" "│"
    
    print_color "$CYAN" "╰─────────────────────────────────────────────────────────────╯"
    echo
}

# Function to display summary
display_summary() {
    local entry_count="$1"
    
    [[ "$QUIET" == true ]] && return
    
    echo
    print_color "$CYAN" "╭─────────────────────────────────────────────────────────────╮"
    print_color "$CYAN" "│ ${BOLD}Summary: $entry_count entries found${NC}${CYAN}"
    
    local summary_padding=$((47 - ${#entry_count}))
    printf "${CYAN}│${NC}"
    printf "%*s" $summary_padding ""
    print_color "$CYAN" "│"
    
    print_color "$CYAN" "╰─────────────────────────────────────────────────────────────╯"
}

# Function to check if log file exists and is readable
validate_log_file() {
    if [[ ! -f "$LOG_FILE" ]]; then
        print_error "Log file not found: $LOG_FILE"
        return 3
    fi
    
    if [[ ! -r "$LOG_FILE" ]]; then
        print_error "Log file not readable: $LOG_FILE"
        print_error "Check file permissions or run with appropriate privileges"
        return 3
    fi
    
    return 0
}

# Main function to process log entries
process_log_entries() {
    local cutoff_timestamp
    local until_timestamp
    local line_count=0
    local entry_count=0
    local current_section_timestamp=""
    local current_section_within_range=false
    
    # Calculate time boundaries
    if [[ -n "$LAST_PULL" ]]; then
        # For --last-pull, populate PULL_DAYS_FILTER first, then get cutoff
        local pull_days
        mapfile -t pull_days < <(find_pull_days "$LAST_PULL")
        
        
        if [[ ${#pull_days[@]} -eq 0 ]]; then
            print_error "No days with Docker updates found in log file"
            return 1
        fi
        
        # Store pull days for filtering
        PULL_DAYS_FILTER=("${pull_days[@]}")
        
        
        # Get cutoff timestamp (oldest day)
        local oldest_day="${pull_days[-1]}"
        cutoff_timestamp=$(date -d "$oldest_day 00:00:00" +%s 2>/dev/null)
        if [[ $? -ne 0 ]]; then
            print_error "Failed to parse oldest pull day: $oldest_day"
            return 1
        fi
    else
        cutoff_timestamp=$(calculate_time_cutoff)
        if [[ $? -ne 0 ]]; then
            return 1
        fi
    fi
    
    until_timestamp=$(get_until_timestamp)
    if [[ $? -ne 0 ]]; then
        print_error "Failed to calculate until timestamp"
        return 1
    fi
    
    # Process log file
    while IFS= read -r line || [[ -n "$line" ]]; do
        ((line_count++))
        
        # Skip empty lines
        [[ -z "$line" ]] && continue
        
        # Check if this line is a timestamp header
        local log_timestamp
        log_timestamp=$(parse_log_timestamp "$line")
        
        if [[ $? -eq 0 ]]; then
            # This is a timestamp header - update current section
            current_section_timestamp="$log_timestamp"
            
            # Check if this section's timestamp is within range
            current_section_within_range=false
            
            if [[ -n "$LAST_PULL" ]]; then
                # Handle --last-pull logic: check if this day is in our pull days filter
                local section_date
                section_date=$(date -d "@$log_timestamp" +%Y-%m-%d 2>/dev/null)
                
                if [[ $? -eq 0 ]]; then
                    # Check if this date is in our PULL_DAYS_FILTER array
                    for pull_day in "${PULL_DAYS_FILTER[@]}"; do
                        if [[ "$section_date" == "$pull_day" ]]; then
                            current_section_within_range=true
                            break
                        fi
                    done
                    
                fi
            elif [[ -n "$SINCE" || -n "$UNTIL" ]]; then
                # Handle --since and --until logic
                if [[ -n "$SINCE" && -n "$UNTIL" ]]; then
                    [[ $log_timestamp -ge $cutoff_timestamp && $log_timestamp -le $until_timestamp ]] && current_section_within_range=true
                elif [[ -n "$SINCE" ]]; then
                    [[ $log_timestamp -ge $cutoff_timestamp ]] && current_section_within_range=true
                elif [[ -n "$UNTIL" ]]; then
                    [[ $log_timestamp -le $until_timestamp ]] && current_section_within_range=true
                fi
            elif [[ -z "$LAST_PULL" ]]; then
                # Handle time range logic (hours, days, minutes) - but NOT for --last-pull
                [[ $log_timestamp -ge $cutoff_timestamp && $log_timestamp -le $until_timestamp ]] && current_section_within_range=true
            fi
            
            # Include the timestamp header itself if within range
            if [[ "$current_section_within_range" == true ]]; then
                ((entry_count++))
                format_output_line "$entry_count" "$line"
            fi
        else
            # This is a regular log line - use current section timestamp
            if [[ -n "$current_section_timestamp" && "$current_section_within_range" == true ]]; then
                # Skip verbose downloading and extracting progress lines (but keep completion messages)
                if [[ "$line" =~ ([Dd]ownloading|[Ee]xtracting)[[:space:]]+\[ ]]; then
                    # Skip downloading/extracting progress lines with progress bars
                    continue
                fi
                
                ((entry_count++))
                format_output_line "$entry_count" "$line"
            fi
            # Note: Lines without timestamps and not in a valid time range section are silently skipped
        fi
        
    done < "$LOG_FILE"
    
    return "$entry_count"
}

# Main execution function
main() {
    # Parse command-line arguments
    if ! parse_arguments "$@"; then
        exit 2
    fi
    
    # Show help if requested
    if [[ "$SHOW_HELP" == true ]]; then
        display_usage
        exit 0
    fi
    
    # Validate arguments
    if ! validate_arguments; then
        exit 2
    fi
    
    # Validate log file
    if ! validate_log_file; then
        exit 3
    fi
    
    # Display header
    display_header
    
    # Process log entries
    process_log_entries
    local entry_count=$?
    
    # Display summary
    display_summary "$entry_count"
    
    exit 0
}

# Execute main function with all arguments
main "$@"