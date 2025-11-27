#!/bin/bash
mkdir -p out
TEMP_WORK_DIR=$(mktemp -d)
cp src/archive.tar.gz "$TEMP_WORK_DIR/"
extract_archives() {
    local file="$1"
    local temp_dir="$2"
    if [[ "$file" == *.tar.gz ]]; then
        tar -xzf "$file" -C "$temp_dir"
    elif [[ "$file" == *.tar ]]; then
        tar -xf "$file" -C "$temp_dir"
    fi
    rm "$file"
    local archives=("$temp_dir"/*.tar.gz "$temp_dir"/*.tar)
    for archive in "${archives[@]}"; do
        if [[ -f "$archive" ]]; then
            extract_archives "$archive" "$temp_dir"
        fi
    done
}
extract_archives "$TEMP_WORK_DIR/archive.tar.gz" "$TEMP_WORK_DIR"
find "$TEMP_WORK_DIR" -type f ! -name "*.tar.gz" ! -name "*.tar" | while read -r final_file; do
    cp "$final_file" "out/$(basename "$final_file")"
done
rm -rf "$TEMP_WORK_DIR"
