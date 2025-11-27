#!/bin/bash

n=$1

for ((i = 1; i <= n; i++)); do
    row=""
    for ((j = 1; j <= i; j++)); do
        if [ $j -eq 1 ]; then
            row="*"
        else
            row="$row *"
        fi
    done
    echo "$row"
done