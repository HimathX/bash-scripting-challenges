#!/usr/bin/env python3
import json
import os

inventory = {
    "_meta": {
        "hostvars": {}
    }
}

servers_dir = './src/servers'
for server_file in os.listdir(servers_dir):
    if not server_file.endswith('.json'):
        continue
    
    with open(os.path.join(servers_dir, server_file)) as f:
        server = json.load(f)
    
    hostname = server.get('hostname')
    role = server.get('role', 'ungrouped')
    
    if role not in inventory:
        inventory[role] = {"hosts": [], "vars": {}}
    
    inventory[role]["hosts"].append(hostname)
    inventory["_meta"]["hostvars"][hostname] = server

print(json.dumps(inventory, indent=2))
