#!/bin/bash

num=$1

if [ -z "$num" ]; then
    echo "Neither"
    exit 0
fi

if ! [[ "$num" =~ ^-?[0-9]+$ ]]; then
    echo "Neither"
    exit 0
fi

if [ "$num" -le 1 ]; then
    echo "Neither"
    exit 0
fi

if [ "$num" -eq 2 ]; then
    echo "Prime"
    exit 0
fi

if [ $((num % 2)) -eq 0 ]; then
    echo "Composite"
    exit 0
fi

i=3
while [ $((i * i)) -le "$num" ]; do
    if [ $((num % i)) -eq 0 ]; then
        echo "Composite"
        exit 0
    fi
    i=$((i + 2))
done

echo "Prime"
