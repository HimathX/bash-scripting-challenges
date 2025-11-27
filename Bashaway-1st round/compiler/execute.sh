#!/bin/bash

mkdir -p ./out

c_source=""
for file in ./src/*.c; do
    if [ -f "$file" ]; then
        c_source="$file"
        break
    fi
done

if [ -z "$c_source" ]; then
    echo "Error: No C source file found in ./src/"
    exit 1
fi

echo "[*] Found C source: $c_source"

if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" || "$OSTYPE" == "win32" ]]; then
    output_exe="./out/phantom.exe"
else
    output_exe="./out/phantom"
fi

echo "[*] Compiling C code..."

if command -v gcc &> /dev/null; then
    gcc "$c_source" -o "$output_exe"
    compile_status=$?
elif command -v clang &> /dev/null; then
    clang "$c_source" -o "$output_exe"
    compile_status=$?
elif command -v cc &> /dev/null; then
    cc "$c_source" -o "$output_exe"
    compile_status=$?
else
    echo "Error: No C compiler found (gcc, clang, or cc)"
    exit 1
fi

if [ $compile_status -ne 0 ]; then
    echo "Error: Compilation failed with exit code $compile_status"
    exit 1
fi

if [ ! -f "$output_exe" ]; then
    echo "Error: Executable was not created at $output_exe"
    exit 1
fi

chmod +x "$output_exe"

echo "[✓] Compilation successful!"
echo "[✓] Executable created: $output_exe"