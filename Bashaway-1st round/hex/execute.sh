#!/bin/bash

num=$1
hex=$(printf '%x' "$num")

result=""
for ((i = 0; i < ${#hex}; i++)); do
    char="${hex:$i:1}"
    
    if [[ "$char" =~ [a-f] ]]; then
        if ((i % 2 == 0)); then
            result+=$(echo "$char" | tr '[:lower:]' '[:upper:]')
        else
            result+=$(echo "$char" | tr '[:upper:]' '[:lower:]')
        fi
    else
        result+="$char"
    fi
done

echo "$result"