import json

# Load the generated topology
input_file = '/Users/macbook/OSPF-LL-JSON/netviz-pro-topo-extra layers.json'

with open(input_file, 'r') as f:
    data = json.load(f)

nodes = data['nodes']
links = data['links']

print("=" * 80)
print("TOPOLOGY VALIDATION REPORT")
print("=" * 80)

# 1. Calculate neighbor counts for each node
neighbor_counts = {}
for node in nodes:
    neighbor_counts[node['id']] = 0

for link in links:
    src = link['source']
    dst = link['target']
    
    # Handle case where source/target might be objects
    src_id = src['id'] if isinstance(src, dict) else src
    dst_id = dst['id'] if isinstance(dst, dict) else dst
    
    if src_id in neighbor_counts:
        neighbor_counts[src_id] += 1
    if dst_id in neighbor_counts:
        neighbor_counts[dst_id] += 1

# Update nodes with neighbor counts
for node in nodes:
    node['neighbor_count'] = neighbor_counts.get(node['id'], 0)

# 2. Validate structure
print(f"\n✓ Total Nodes: {len(nodes)}")
print(f"✓ Total Links: {len(links)}")

# 3. Country distribution
country_dist = {}
for node in nodes:
    c = node['country']
    if c not in country_dist:
        country_dist[c] = 0
    country_dist[c] += 1

print(f"\n📊 Country Distribution:")
for country, count in sorted(country_dist.items()):
    print(f"   {country}: {count} nodes")

# 4. Validate ZAF has 40% more than others
new_countries = ['ZAF', 'LSO', 'MOZ', 'PRT', 'FRA']
new_counts = {c: country_dist.get(c, 0) for c in new_countries}
zaf_count = new_counts['ZAF']
other_counts = [v for k, v in new_counts.items() if k != 'ZAF']
max_other = max(other_counts) if other_counts else 0

if zaf_count >= max_other * 1.4:
    print(f"\n✓ ZAF Requirement Met: {zaf_count} nodes (>= {max_other * 1.4:.1f})")
else:
    print(f"\n✗ ZAF Requirement NOT Met: {zaf_count} nodes (< {max_other * 1.4:.1f})")

# 5. Validate link structure
print(f"\n🔗 Link Validation:")
missing_fields = []
for i, link in enumerate(links):
    required = ['source', 'target', 'source_interface', 'target_interface', 
                'forward_cost', 'reverse_cost', 'cost', 'status']
    for field in required:
        if field not in link:
            missing_fields.append(f"Link {i}: missing '{field}'")

if missing_fields:
    print(f"   ✗ {len(missing_fields)} issues found:")
    for issue in missing_fields[:10]:  # Show first 10
        print(f"      - {issue}")
else:
    print(f"   ✓ All links have required fields")

# 6. Neighbor count stats
neighbor_stats = list(neighbor_counts.values())
print(f"\n📈 Neighbor Count Statistics:")
print(f"   Min: {min(neighbor_stats)}")
print(f"   Max: {max(neighbor_stats)}")
print(f"   Avg: {sum(neighbor_stats) / len(neighbor_stats):.2f}")

# Find isolated nodes
isolated = [nid for nid, count in neighbor_counts.items() if count == 0]
if isolated:
    print(f"\n⚠️  Isolated Nodes (0 neighbors): {len(isolated)}")
    for nid in isolated[:5]:
        print(f"      - {nid}")
else:
    print(f"\n✓ No isolated nodes")

# 7. Save updated topology with neighbor counts
data['nodes'] = nodes
with open(input_file, 'w') as f:
    json.dump(data, f, indent=2)

print(f"\n✓ Updated topology saved with neighbor_count field")
print("=" * 80)
