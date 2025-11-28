import colorsys

# FIXED color assignments
COLORS = {
    'ZWE': '#10b981',  # Emerald - DISTINCT
    'USA': '#2563eb',  # Blue-dark - CHANGED
    'DEU': '#f59e0b',  # Amber
    'GBR': '#ef4444',  # Red
    'ZAF': '#d946ef',  # Fuchsia - CHANGED
    'LSO': '#facc15',  # Yellow - CHANGED
    'MOZ': '#06b6d4',  # Cyan - CHANGED
    'PRT': '#16a34a',  # Green-dark - CHANGED
    'FRA': '#ec4899',  # Pink - CHANGED
}

def hex_to_rgb(hex_color):
    """Convert hex to RGB"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def color_distance(color1, color2):
    """Calculate perceptual color distance"""
    rgb1 = hex_to_rgb(color1)
    rgb2 = hex_to_rgb(color2)
    return sum((a - b) ** 2 for a, b in zip(rgb1, rgb2)) ** 0.5

print("=" * 80)
print("FIXED COLOR VALIDATION")
print("=" * 80)
print()

countries = list(COLORS.keys())
min_distance = float('inf')
min_pair = None

print("📊 ALL PAIRWISE DISTANCES:")
print()

for i, c1 in enumerate(countries):
    for c2 in countries[i+1:]:
        dist = color_distance(COLORS[c1], COLORS[c2])
        status = "✓" if dist >= 100 else "⚠️"
        print(f"{status} {c1} ↔ {c2}: {dist:.2f}")
        
        if dist < min_distance:
            min_distance = dist
            min_pair = (c1, c2)

print()
print("=" * 80)
print("VALIDATION RESULTS")
print("=" * 80)
print()

# Check for similar colors
similar_count = 0
for i, c1 in enumerate(countries):
    for c2 in countries[i+1:]:
        dist = color_distance(COLORS[c1], COLORS[c2])
        if dist < 100:
            similar_count += 1

if similar_count == 0:
    print("✅ SUCCESS: All color pairs are sufficiently distinct!")
    print(f"   Minimum distance: {min_distance:.2f} between {min_pair[0]} and {min_pair[1]}")
else:
    print(f"❌ FAILURE: {similar_count} color pairs are too similar")

print()
print("=" * 80)
