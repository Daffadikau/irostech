#!/bin/bash

# Daily Work Log Script
# Usage: ./daily_log.sh start   # Start your day
#        ./daily_log.sh end     # End your day

LOG_DIR="$HOME/AI-Internship-Workspace/daily-logs"
CURRENT_MONTH=$(date +%Y-%m)
LOG_FILE="$LOG_DIR/$CURRENT_MONTH.md"

# Create log directory if it doesn't exist
mkdir -p "$LOG_DIR"

# Create monthly log file if it doesn't exist
if [ ! -f "$LOG_FILE" ]; then
    echo "# Work Log - $CURRENT_MONTH" > "$LOG_FILE"
    echo "" >> "$LOG_FILE"
fi

if [ "$1" == "start" ]; then
    echo "" >> "$LOG_FILE"
    echo "## $(date '+%Y-%m-%d %A')" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "**Start Time:** $(date '+%I:%M %p')" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### Today's Plan:" >> "$LOG_FILE"
    echo "- [ ] Task 1" >> "$LOG_FILE"
    echo "- [ ] Task 2" >> "$LOG_FILE"
    echo "- [ ] Task 3" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### Progress:" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    
    echo "✅ Daily log started! Edit your plan: $LOG_FILE"
    
elif [ "$1" == "end" ]; then
    echo "" >> "$LOG_FILE"
    echo "**End Time:** $(date '+%I:%M %p')" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### Completed Today:" >> "$LOG_FILE"
    echo "- " >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### Blockers/Questions:" >> "$LOG_FILE"
    echo "- None / [List any]" >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "### Learnings:" >> "$LOG_FILE"
    echo "- " >> "$LOG_FILE"
    echo "" >> "$LOG_FILE"
    echo "---" >> "$LOG_FILE"
    
    echo "✅ Daily log ended! Review: $LOG_FILE"
    
else
    echo "Usage: ./daily_log.sh [start|end]"
    echo "  start - Begin your workday"
    echo "  end   - End your workday"
fi
