#!/bin/bash
# https://medium.com/@adilrk/linux-oom-out-of-memory-killer-74fbae6dc1b0
# This script retrieves and displays the OOM (Out Of Memory) score and the OOM adjusted score 
# for each running process, sorted in descending order by the OOM score.

printf 'PID\tOOM Score\tOOM Adj\tCommand\n'

# Read each process ID and command, check if a corresponding oom_score file exists and its value is not zero.
# If so, print the process ID, OOM score, OOM adjusted score, and command.
while read -r pid comm
do
    if [ -f /proc/$pid/oom_score ] && [ $(cat /proc/$pid/oom_score) != 0 ]
    then
        printf '%d\t%d\t\t%d\t%s\n' "$pid" "$(cat /proc/$pid/oom_score)" "$(cat /proc/$pid/oom_score_adj)" "$comm"
    fi
done < <(ps -e -o pid= -o comm=) | sort -k 2nr
