#!/bin/bash
cd src
for f in *; do
  if grep -qE "$1" <<<"$f"; then
    mv "$f" "${f%.*}_renamed.${f##*.}"
  fi
done
