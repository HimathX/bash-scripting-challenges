#!/bin/bash
mkdir -p out
awk -F, 'NR>1{a[$1]+=$2;b[$1]+=$3;c[$1]++}END{print "category,total_amount,total_quantity";for(i in a)print i","a[i]","b[i]}' src/data.csv>out/result.csv
