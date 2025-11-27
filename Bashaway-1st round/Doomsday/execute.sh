#!/bin/bash

# Friday Doomsday: Generate Ansible infrastructure from server metadata

# Create output directories
mkdir -p ./out/playbooks ./out/roles ./out/group_vars ./out/host_vars ./out/inventory

# Initialize data structures
declare -A SERVER_ROLES
declare -a ALL_SERVERS
declare -a ALL_ROLES

# Parse JSON without jq - simple bash parsing
parse_json() {
    local file=$1
    local key=$2
    grep "\"$key\"" "$file" | head -1 | sed 's/.*"'"$key"'"\s*:\s*"\([^"]*\).*/\1/'
}

# Step 1: Parse server metadata and group by role
echo "[*] Scanning server metadata..."
for server_file in ./src/servers/*.json; do
    [ -f "$server_file" ] || continue
    
    hostname=$(parse_json "$server_file" "hostname")
    ip=$(parse_json "$server_file" "ip")
    role=$(parse_json "$server_file" "role")
    
    [ -z "$hostname" ] && continue
    
    ALL_SERVERS+=("$hostname")
    
    # Group servers by role
    if [[ -z "${SERVER_ROLES[$role]}" ]]; then
        SERVER_ROLES[$role]="$hostname"
        ALL_ROLES+=("$role")
    else
        SERVER_ROLES[$role]="${SERVER_ROLES[$role]} $hostname"
    fi
done

# Step 2: Generate dynamic inventory script
echo "[*] Generating dynamic inventory..."

cat > ./out/inventory/hosts.ini << 'EOF'
[all]
EOF

for server_file in ./src/servers/*.json; do
    [ -f "$server_file" ] || continue
    hostname=$(parse_json "$server_file" "hostname")
    ip=$(parse_json "$server_file" "ip")
    [ -z "$hostname" ] && continue
    echo "$hostname ansible_host=$ip" >> ./out/inventory/hosts.ini
done

# Add role groups
for role in "${ALL_ROLES[@]}"; do
    echo "" >> ./out/inventory/hosts.ini
    echo "[$role]" >> ./out/inventory/hosts.ini
    
    for server_file in ./src/servers/*.json; do
        [ -f "$server_file" ] || continue
        server_role=$(parse_json "$server_file" "role")
        hostname=$(parse_json "$server_file" "hostname")
        
        if [ "$server_role" = "$role" ]; then
            echo "$hostname" >> ./out/inventory/hosts.ini
        fi
    done
done

# Create Python inventory script
cat > ./out/inventory.py << 'PYEOF'
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
PYEOF

chmod +x ./out/inventory.py

# Step 3: Create roles for each role type
echo "[*] Generating Ansible roles..."
for role in "${ALL_ROLES[@]}"; do
    role_dir="./out/roles/$role"
    mkdir -p "$role_dir"/{tasks,handlers,vars,templates}
    
    # Create tasks/main.yml
    cat > "$role_dir/tasks/main.yml" << TASKSEOF
---
# Role: $role
# Auto-generated Ansible role for $role servers

- name: Update package cache
  apt:
    update_cache: yes
    cache_valid_time: 3600
  when: ansible_os_family == "Debian"

- name: Install required packages
  package:
    name: "{{ packages }}"
    state: present
  notify: "restart-services"

- name: Ensure services are enabled
  systemd:
    name: "{{ item }}"
    enabled: yes
    state: started
  loop: "{{ services }}"
  when: services is defined

- name: Deploy configuration files
  template:
    src: "{{ item.src }}"
    dest: "{{ item.dest }}"
    owner: root
    group: root
    mode: '0644'
  loop: "{{ config_files }}"
  when: config_files is defined
  notify: "reload-services"
TASKSEOF

    # Create handlers/main.yml
    cat > "$role_dir/handlers/main.yml" << HANDLERSEOF
---
# Handlers for $role role

- name: restart-services
  systemd:
    name: "{{ item }}"
    state: restarted
  loop: "{{ services }}"
  when: services is defined

- name: reload-services
  systemd:
    name: "{{ item }}"
    state: reloaded
  loop: "{{ services }}"
  when: services is defined

- name: restart-networking
  service:
    name: networking
    state: restarted
HANDLERSEOF

    # Create vars/main.yml
    cat > "$role_dir/vars/main.yml" << VARSEOF
---
# Variables for $role role

packages: []
services: []
config_files: []
VARSEOF

    # Create README
    cat > "$role_dir/README.md" << READMEEOF
# Ansible Role: $role

Auto-generated role for managing $role servers.

## Variables

- \`packages\`: List of packages to install
- \`services\`: List of services to manage
- \`config_files\`: Configuration file templates to deploy

## Usage

Include in playbook:

\`\`\`yaml
- hosts: $role
  roles:
    - $role
\`\`\`
READMEEOF
done

# Step 4: Generate playbooks
echo "[*] Generating Ansible playbooks..."

cat > ./out/playbooks/site.yml << 'SITEEOF'
---
# Master Playbook: Site Configuration
# Auto-generated playbook for Friday Doomsday infrastructure

- name: Configure all servers
  hosts: all
  gather_facts: yes
  vars_files:
    - ../group_vars/all.yml
  tasks:
    - name: Ensure system is up to date
      apt:
        update_cache: yes
        upgrade: dist
      become: yes
      when: ansible_os_family == "Debian"
SITEEOF

# Role-specific playbooks
for role in "${ALL_ROLES[@]}"; do
    cat >> ./out/playbooks/site.yml << ROLEEOF

- name: Configure $role servers
  hosts: $role
  gather_facts: yes
  roles:
    - $role
ROLEEOF

    # Create individual playbook for each role
    cat > "./out/playbooks/${role}.yml" << INDIVEOF
---
# Playbook for $role role

- name: Deploy $role configuration
  hosts: $role
  become: yes
  gather_facts: yes
  roles:
    - role: ../roles/$role
      vars:
        packages: []
        services: []
INDIVEOF
done

# Step 5: Create group variables
echo "[*] Creating group variables..."

cat > ./out/group_vars/all.yml << 'ALLEOF'
---
# Global group variables

ansible_user: root
ansible_become_method: sudo
ansible_python_interpreter: /usr/bin/python3

# Common settings
ntp_enabled: true
selinux_state: disabled
firewall_enabled: true
ALLEOF

# Per-role group variables
for role in "${ALL_ROLES[@]}"; do
    cat > "./out/group_vars/${role}.yml" << GROUPEOF
---
# Group variables for $role

packages: []
services: []

# Role-specific configuration
role_name: $role
GROUPEOF
done

# Step 6: Create host variables
echo "[*] Creating host variables..."

for server_file in ./src/servers/*.json; do
    [ -f "$server_file" ] || continue
    
    hostname=$(parse_json "$server_file" "hostname")
    [ -z "$hostname" ] && continue
    
    cat > "./out/host_vars/${hostname}.yml" << HOSTEOF
---
# Host variables for $hostname

$(cat "$server_file" | sed 's/[{}]//g' | tr ',' '\n' | sed 's/^ *//;s/ *$//' | grep -v '^$')
HOSTEOF
done

echo ""
echo "[✓] Friday Doomsday - Ansible generation complete!"
echo "[✓] Generated:"
echo "    - Inventory: ./out/inventory/, ./out/inventory.py"
echo "    - Roles: ./out/roles/"
echo "    - Playbooks: ./out/playbooks/"
echo "    - Variables: ./out/group_vars/, ./out/host_vars/"