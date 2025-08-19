# Troubleshooting Guide - Proxmox Update Log Viewer

## Common Issues and Solutions

### Issue 1: Script Shows All Log Entries Instead of Filtering by Time

**Symptoms:**
- Script shows "Last 24 hours" but displays entries from several days ago
- Entry count much higher than expected (e.g., 185 entries instead of recent ones)

**Cause:** 
Timestamp parsing is failing, causing the script to include all entries.

**Solution:**
1. Test the timestamp parsing with the debug script:
   ```bash
   ./debug-script.sh
   ```

2. Check if your log file has the expected timestamp format:
   ```bash
   grep -E "(====|####)" /var/log/update-logs/update.log | head -5
   ```

3. If timestamps are in a different format, the script may need adjustment.

### Issue 2: Many "Could not parse timestamp" Warnings

**Symptoms:**
- Warnings like "WARNING: Line X: Could not parse timestamp, including anyway"
- Script includes lines without filtering

**Cause:**
Most log lines don't have timestamps - they belong to sections marked by timestamp headers.

**Solution:**
This has been fixed in the updated script. The warnings should no longer appear.

### Issue 3: Log File Not Found

**Symptoms:**
- "ERROR: Log file not found: /var/log/update-logs/update.log"

**Solutions:**
1. Check if the log directory exists:
   ```bash
   ls -la /var/log/update-logs/
   ```

2. Create the directory if missing:
   ```bash
   sudo mkdir -p /var/log/update-logs
   ```

3. Check if the log file has a different name:
   ```bash
   find /var/log -name "*update*" -type f
   ```

4. Modify the script to use the correct path:
   ```bash
   # Edit the LOG_FILE variable in the script
   readonly LOG_FILE="/path/to/your/update.log"
   ```

### Issue 4: Permission Denied

**Symptoms:**
- "ERROR: Log file not readable: /var/log/update-logs/update.log"

**Solutions:**
1. Check file permissions:
   ```bash
   ls -la /var/log/update-logs/update.log
   ```

2. Run with sudo:
   ```bash
   sudo ./view-update-log.sh
   ```

3. Change file permissions (if appropriate):
   ```bash
   sudo chmod +r /var/log/update-logs/update.log
   ```

### Issue 5: Date Command Errors

**Symptoms:**
- "Failed to calculate time cutoff"
- "Failed to parse timestamp"

**Cause:**
Different date command versions or locale settings.

**Solutions:**
1. Test basic date functionality:
   ```bash
   date -d "24 hours ago"
   date -d "Jul 23 05:00:01 AM 2025"
   ```

2. Check locale settings:
   ```bash
   locale
   ```

3. Set appropriate locale:
   ```bash
   export LC_TIME=C
   export LANG=C
   ```

## Debugging Steps

### Step 1: Test Basic Functionality
```bash
# Test timestamp parsing
./debug-script.sh

# Test with verbose output
./view-update-log.sh --hours 1
```

### Step 2: Check Log File Format
```bash
# Look at the structure of your log file
head -20 /var/log/update-logs/update.log
tail -20 /var/log/update-logs/update.log

# Find timestamp headers
grep -n "===\|###" /var/log/update-logs/update.log
```

### Step 3: Test Time Calculations
```bash
# Check current time
date

# Check 24 hours ago
date -d "24 hours ago"

# Test custom time range
./view-update-log.sh --hours 1
./view-update-log.sh --days 1
```

### Step 4: Test Different Options
```bash
# Test with no colors for cleaner output
./view-update-log.sh --no-color --hours 6

# Test quiet mode
./view-update-log.sh --quiet --hours 12

# Test specific date range
./view-update-log.sh --since "$(date -d '1 day ago' '+%Y-%m-%d')"
```

## Expected Log Format

The script expects timestamp headers in these formats:

```
==== Thu Jul 17 05:00:01 AM CEST 2025 ====
########## Wed Jul 23 05:00:01 AM CEST 2025 ##########
```

Log entries between these headers are considered part of that time section.

## Manual Testing

### Test 1: Verify Time Filtering
```bash
# This should show only very recent entries
./view-update-log.sh --hours 1

# This should show more entries
./view-update-log.sh --hours 24
```

### Test 2: Verify Timestamp Parsing
```bash
# Check what timestamp headers exist
grep -E "(====|####)" /var/log/update-logs/update.log

# Test parsing a specific timestamp
date -d "Jul 23 05:00:01 AM 2025" +%s
```

### Test 3: Compare Entry Counts
```bash
# Total lines in log file
wc -l /var/log/update-logs/update.log

# Lines shown by script
./view-update-log.sh --quiet | wc -l

# Recent timestamp headers
grep -E "(====|####)" /var/log/update-logs/update.log | \
  while read line; do
    if [[ "$line" =~ ([A-Za-z]{3}[[:space:]]+[0-9]{1,2}[[:space:]]+[0-9]{2}:[0-9]{2}:[0-9]{2}[[:space:]]+[AP]M[[:space:]]+[A-Z]{3,4}[[:space:]]+[0-9]{4}) ]]; then
      timestamp="${BASH_REMATCH[1]}"
      echo "Found: $timestamp"
    fi
  done
```

## Contact Information

If you continue to experience issues:
1. Run the debug script and share the output
2. Share a sample of your log file format
3. Provide your system information (`uname -a`, `date --version`)
4. Test with the troubleshooting commands above

The script has been tested with standard Proxmox update logs but may need adjustment for custom log formats.