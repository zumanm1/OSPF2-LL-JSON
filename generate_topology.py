import json
import random
import datetime
import re

# Load existing topology
input_file = '/Users/macbook/OSPF-LL-JSON/netviz-pro-topology-2025-11-27T22_03_52.070Z.json'
output_file = '/Users/macbook/OSPF-LL-JSON/netviz-pro-topo-extra layers.json'

with open(input_file, 'r') as f:
    data = json.load(f)

existing_nodes = data['nodes']
existing_links = data['links']

print(f"Existing nodes: {len(existing_nodes)}")
print(f"Existing links: {len(existing_links)}")

# --- 1. Analyze Interface Usage on Existing Nodes ---
# We need to track the next available interface index for each node
# to avoid collisions and ensure realistic data.
# Format: GigabitEthernet0/0/0/X

interface_counters = {}

def get_interface_index(interface_name):
    # Extract the last number from the interface string
    match = re.search(r'/(\d+)$', interface_name)
    if match:
        return int(match.group(1))
    return 0

# Initialize counters for existing nodes
for node in existing_nodes:
    interface_counters[node['id']] = 0

# Scan existing links to find max used index
for link in existing_links:
    src = link['source']
    dst = link['target']
    
    # Handle case where source/target might be objects (though in JSON they are usually strings)
    src_id = src['id'] if isinstance(src, dict) else src
    dst_id = dst['id'] if isinstance(dst, dict) else dst
    
    src_idx = get_interface_index(link.get('source_interface', ''))
    dst_idx = get_interface_index(link.get('target_interface', ''))
    
    if src_id in interface_counters:
        interface_counters[src_id] = max(interface_counters[src_id], src_idx)
    else:
        interface_counters[src_id] = src_idx
        
    if dst_id in interface_counters:
        interface_counters[dst_id] = max(interface_counters[dst_id], dst_idx)
    else:
        interface_counters[dst_id] = dst_idx

print("Initialized interface counters for existing nodes.")

# Helper to get next interface
def get_next_interface(node_id):
    if node_id not in interface_counters:
        interface_counters[node_id] = 0
    interface_counters[node_id] += 1
    return f"GigabitEthernet0/0/0/{interface_counters[node_id]}"

# --- 2. Configuration for Expansion ---
target_total = 100
current_count = len(existing_nodes)
needed = target_total - current_count

# New countries and distribution
# ZAF, LSO, MOZ, PRT, FRA
# Requirement: ZAF has 40% more routers than any other new country.
# Config: ZAF: 24, Others: ~16-17. 24 is > 1.4 * 17 (23.8).
new_countries_config = {
    'ZAF': 24,
    'LSO': 16,
    'MOZ': 17,
    'PRT': 16,
    'FRA': 17
}

# Verify sum
total_new = sum(new_countries_config.values())
if total_new != needed:
    print(f"Adjustment needed. Sum: {total_new}, Needed: {needed}")
    # Adjust FRA to match exactly if needed
    diff = needed - total_new
    new_countries_config['FRA'] += diff
    print(f"Adjusted FRA to {new_countries_config['FRA']}")

new_nodes = []
new_links = []

# --- 3. Generate New Nodes ---
def create_node(country, idx):
    node_id = f"{country.lower()}-r{idx}"
    # IP Scheme: 172.16.X.X where X is unique.
    # Existing are 172.16.1.1 to 172.16.10.10 roughly.
    # We start new ones from 100.
    # To ensure uniqueness and "same structure", we use 172.16.A.A style if possible,
    # or 172.16.100+N.N
    
    # Let's use a continuous counter for the 3rd octet to be safe and distinct
    unique_num = 100 + len(new_nodes)
    
    return {
        "id": node_id,
        "name": node_id,
        "hostname": node_id,
        "loopback_ip": f"172.16.{unique_num}.{idx}", 
        "country": country,
        "is_active": True,
        "node_type": "router"
    }

country_nodes = {c: [] for c in new_countries_config}
for country, count in new_countries_config.items():
    for i in range(1, count + 1):
        node = create_node(country, i)
        new_nodes.append(node)
        country_nodes[country].append(node['id'])
        # Initialize interface counter for new node
        interface_counters[node['id']] = 0

# --- 4. Generate New Links ---
def create_link(src, dst, type="backbone"):
    cost = 10 if type == "backbone" else 100
    
    # Get unique interfaces
    src_int = get_next_interface(src)
    dst_int = get_next_interface(dst)
    
    return {
        "source": src,
        "target": dst,
        "source_interface": src_int,
        "target_interface": dst_int,
        "forward_cost": cost,
        "reverse_cost": cost,
        "cost": cost,
        "status": "up",
        "edge_type": type,
        "is_asymmetric": False,
        "source_capacity": {
            "speed": "1G",
            "is_bundle": False,
            "total_capacity_mbps": 1000
        },
        "target_capacity": {
            "speed": "1G",
            "is_bundle": False,
            "total_capacity_mbps": 1000
        },
        "traffic": {
            "forward_traffic_mbps": 0,
            "forward_utilization_pct": 0,
            "reverse_traffic_mbps": 0,
            "reverse_utilization_pct": 0
        }
    }

# Intra-country links (Ring + Random Chords)
for country, nodes in country_nodes.items():
    # Ring
    for i in range(len(nodes)):
        src = nodes[i]
        dst = nodes[(i + 1) % len(nodes)]
        new_links.append(create_link(src, dst, "backbone"))
    
    # Cross links (30%)
    num_cross = max(2, len(nodes) // 3)
    for _ in range(num_cross):
        src = random.choice(nodes)
        dst = random.choice(nodes)
        if src != dst:
            # Check if link already exists (simple check)
            # In a real graph we'd check adjacency matrix, but for this generator simple is ok
            # We allow parallel links or just ignore duplicates? 
            # Let's just add them, OSPF handles parallel links fine.
            new_links.append(create_link(src, dst, "backbone"))

# Inter-country links (Ring of countries)
countries_list = list(new_countries_config.keys())
for i in range(len(countries_list)):
    c1 = countries_list[i]
    c2 = countries_list[(i + 1) % len(countries_list)]
    
    # Connect 2 routers from c1 to 2 routers from c2 for redundancy
    srcs = random.sample(country_nodes[c1], 2)
    dsts = random.sample(country_nodes[c2], 2)
    for s, d in zip(srcs, dsts):
        new_links.append(create_link(s, d, "backbone"))

# Connect New to Existing (Integration)
# Existing countries: ZWE, USA, DEU, GBR
existing_by_country = {}
for n in existing_nodes:
    c = n['country']
    if c not in existing_by_country:
        existing_by_country[c] = []
    existing_by_country[c].append(n['id'])

# ZAF <-> ZWE
if 'ZWE' in existing_by_country:
    src = random.choice(country_nodes['ZAF'])
    dst = random.choice(existing_by_country['ZWE'])
    new_links.append(create_link(src, dst, "backbone"))

# PRT <-> DEU
if 'DEU' in existing_by_country:
    src = random.choice(country_nodes['PRT'])
    dst = random.choice(existing_by_country['DEU'])
    new_links.append(create_link(src, dst, "backbone"))

# FRA <-> GBR
if 'GBR' in existing_by_country:
    src = random.choice(country_nodes['FRA'])
    dst = random.choice(existing_by_country['GBR'])
    new_links.append(create_link(src, dst, "backbone"))

# USA <-> PRT
if 'USA' in existing_by_country:
    src = random.choice(country_nodes['PRT'])
    dst = random.choice(existing_by_country['USA'])
    new_links.append(create_link(src, dst, "backbone"))

# MOZ <-> ZAF
src = random.choice(country_nodes['MOZ'])
dst = random.choice(country_nodes['ZAF'])
new_links.append(create_link(src, dst, "backbone"))

# LSO <-> ZAF
src = random.choice(country_nodes['LSO'])
dst = random.choice(country_nodes['ZAF'])
new_links.append(create_link(src, dst, "backbone"))

# --- 5. Save Output ---
all_nodes = existing_nodes + new_nodes
all_links = existing_links + new_links

# Update metadata
data['nodes'] = all_nodes
data['links'] = all_links
data['metadata']['node_count'] = len(all_nodes)
data['metadata']['edge_count'] = len(all_links)
data['metadata']['export_timestamp'] = datetime.datetime.now().isoformat()
data['metadata']['description'] = "Expanded topology with 100 routers (Unique Interfaces)"

with open(output_file, 'w') as f:
    json.dump(data, f, indent=2)

print(f"Successfully created {output_file}")
print(f"Total Nodes: {len(all_nodes)}")
print(f"Total Links: {len(all_links)}")
print(f"New Nodes Added: {len(new_nodes)}")
print(f"New Links Added: {len(new_links)}")
