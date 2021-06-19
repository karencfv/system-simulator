#!/bin/bash

# Usage: ./cpu-usage.sh [PID]

numreadings=5 #The number of records to be displayed per minute
timelimit=60
freq=$((60/$numreadings))
timestamp=`date "+%H:%M:%S"`

echo "TIMESTAMP  PID    %CPU    PROCESS"

while [ "$SECONDS" -le "$timelimit" ] ; do
  ps -o pid,pcpu,comm -c | grep $1 | sed "s/^/$timestamp  /"
  sleep $freq
  timestamp=`date "+%H:%M:%S"`
done
