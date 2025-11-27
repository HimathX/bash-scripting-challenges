#!/bin/bash

mkdir -p ./out

declare -A graph
declare -A in_degree
declare -a all_packages
declare -a circular_list

parse_json_deps() {
    local file=$1
    grep -oP '"dependencies"\s*:\s*\{\s*\K[^}]*' "$file" | grep -oP '"([^"]+)"' | sed 's/"//g'
}

extract_name() {
    grep -oP '"name"\s*:\s*"\K[^"]+' "$1"
}

for pkg_dir in ./src/*/; do
    pkg_name=$(basename "$pkg_dir")
    pkg_file="$pkg_dir/package.json"
    
    if [ -f "$pkg_file" ]; then
        actual_name=$(extract_name "$pkg_file")
        [ -z "$actual_name" ] && actual_name="$pkg_name"
        
        all_packages+=("$actual_name")
        graph["$actual_name"]=""
        in_degree["$actual_name"]=0
        
        deps=$(parse_json_deps "$pkg_file")
        while IFS= read -r dep; do
            [ -z "$dep" ] && continue
            graph["$actual_name"]="${graph[$actual_name]}$dep "
            in_degree["$dep"]=$((${in_degree[$dep]:-0} + 1))
        done <<< "$deps"
    fi
done

for pkg in "${all_packages[@]}"; do
    if [ -z "${in_degree[$pkg]}" ]; then
        in_degree[$pkg]=0
    fi
done

declare -a queue
for pkg in "${all_packages[@]}"; do
    if [ ${in_degree[$pkg]} -eq 0 ]; then
        queue+=("$pkg")
    fi
done

declare -a sorted_order
declare -A visited
while [ ${#queue[@]} -gt 0 ]; do
    current="${queue[0]}"
    queue=("${queue[@]:1}")
    
    sorted_order+=("$current")
    visited["$current"]=1
    
    for dep in ${graph[$current]}; do
        if [ -z "${visited[$dep]}" ]; then
            in_degree["$dep"]=$((${in_degree[$dep]} - 1))
            if [ ${in_degree[$dep]} -eq 0 ]; then
                queue+=("$dep")
            fi
        fi
    done
done

{
    echo "{"
    first=true
    for pkg in "${all_packages[@]}"; do
        if [ "$first" = false ]; then
            echo ","
        fi
        echo -n "  \"$pkg\": ["
        
        dep_list=(${graph[$pkg]})
        first_dep=true
        for dep in "${dep_list[@]}"; do
            if [ "$first_dep" = false ]; then
                echo -n ", "
            fi
            echo -n "\"$dep\""
            first_dep=false
        done
        
        echo -n "]"
        first=false
    done
    echo ""
    echo "}"
} > ./out/graph.json

for pkg in "${sorted_order[@]}"; do
    echo "$pkg"
done > ./out/order.txt

circular=""
for pkg in "${all_packages[@]}"; do
    deps=(${graph[$pkg]})
    for dep in "${deps[@]}"; do
        if [[ " ${graph[$dep]} " =~ " $pkg " ]]; then
            circular="$circular$pkg <-> $dep\n"
        fi
    done
done

if [ ! -z "$circular" ]; then
    echo -e "$circular" > ./out/circular.txt
else
    echo "" > ./out/circular.txt
fi

echo "[✓] Chain of Favors - Complete!"