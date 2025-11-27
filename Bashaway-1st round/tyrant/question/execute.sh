#!/bin/bash
mkdir -p out
python3 << 'PYSCRIPT'
import json
import yaml

with open('src/data.json', 'r') as f:
    data = json.load(f)

def sort_keys_recursively(obj):
    if isinstance(obj, list):
        return [sort_keys_recursively(item) for item in obj]
    elif isinstance(obj, dict):
        return {k: sort_keys_recursively(obj[k]) for k in sorted(obj.keys())}
    return obj

sorted_data = sort_keys_recursively(data)

with open('out/transformed.yaml', 'w') as f:
    yaml.dump(sorted_data, f, sort_keys=False, default_flow_style=False)
PYSCRIPT
