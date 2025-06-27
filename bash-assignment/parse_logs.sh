#!/bin/bash
LOGFILE="./logfile.log"

# --- Task 1: Find the request with the longest duration ---
paste - - < "$LOGFILE"|sed 's/.*in \([0-9]*\)ms.*/\1 &/'|sort -rn|head -n1|sed 's/^[0-9]* //'

# --- Task 2: Count unique endpoints ---

grep "Started" "$LOGFILE"|sed -E 's/.*Started (GET|POST) "([^?"]+).*/\1 \2/'|sort|uniq -c|sort -rn
