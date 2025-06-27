#!/bin/bash

# ==============================================================================
# Bash Log Parsing Assignment Script
#
# This script performs two tasks on the specified log file:
# 1. Finds the request that took the longest time to complete.
# 2. Counts the number of times each unique endpoint was requested.
# The entire output is saved to sample_output.txt.
#
# Usage:

# 1. Save this file as "parse_logs.sh".
# 2. Create the logfile.log with the provided log data in the same directory.
# 3. Make the script executable: chmod +x parse_logs.sh
# 4. Run the script: ./parse_logs.sh
# ==============================================================================

# Define the log file and the output file
LOGFILE="./logfile.log"
OUTPUT_FILE="./sample_output.txt"

# Check if the log file exists
if [ ! -f "$LOGFILE" ]; then
    echo "Error: Log file not found at '$LOGFILE'"
    echo "Please create it and populate it with the log data."
    exit 1
fi

# Group all commands and redirect their collective output to the output file.
# The '>' operator creates the file or overwrites it if it already exists.
{
    echo "--- Log Parsing Assignment Results ---"
    echo ""

    # --- Task 1: Find the request with the longest duration ---
    echo "1. Request with the Longest Duration:"

    # Explanation:
    # 1. `paste - - < "$LOGFILE"`: Merges every two lines (Started/Completed) into a single line, separated by a tab.
    # 2. `sed 's/.*in \([0-9]*\)ms.*/\1 &/'`: Uses a regular expression to find the millisecond value in the "Completed" part,
    #    captures the number, and prepends it to the start of the line. This makes numeric sorting easy.
    # 3. `sort -rn`: Sorts all the combined lines numerically (-n) and in reverse order (-r).
    # 4. `head -n1`: Takes the top line, which is now the one with the highest duration.
    # 5. `sed 's/^[0-9]* //'`: Cleans up the output by removing the prepended number and space.
    paste - - < "$LOGFILE" | sed 's/.*in \([0-9]*\)ms.*/\1 &/' | sort -rn | head -n1 | sed 's/^[0-9]* //'

    echo ""
    echo "----------------------------------------"
    echo ""

    # --- Task 2: Count unique endpoints ---
    echo "2. Unique Endpoint Hit Counts:"

    # Explanation:
    # 1. `grep "Started" "$LOGFILE"`: Filters the file to get only the lines that contain request details.
    # 2. `sed -E 's/.*Started (GET|POST) "([^?"]+).*/\1 \2/'`: Extracts the HTTP Method (GET or POST) and the
    #    URL path. The `[^?"]+` part captures everything up to a '?' or a '"', effectively removing query strings.
    # 3. `sort`: Sorts the list of endpoints alphabetically. This is necessary for `uniq` to work correctly.
    # 4. `uniq -c`: Collapses the sorted list, counting (-c) the number of adjacent identical lines.
    # 5. `sort -rn`: Sorts the final counted list numerically (-n) and in reverse (-r) to show the most popular endpoints first.
    grep "Started" "$LOGFILE" | sed -E 's/.*Started (GET|POST) "([^?"]+).*/\1 \2/' | sort | uniq -c | sort -rn

    echo ""
    echo "--- End of Report ---"

} > "$OUTPUT_FILE"

# Add a confirmation message to the console so the user knows the script has finished.
echo "Script finished. Results have been saved to '$OUTPUT_FILE'."
