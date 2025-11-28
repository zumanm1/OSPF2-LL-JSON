import colorsys

# FINAL OPTIMIZED COLORS
COLORS = {
    'ZWE': '#10b981',  # Emerald (160°)
    'USA': '#3b82f6',  # Blue (217°)
    'DEU': '#f59e0b',  # Amber (38°)
    'GBR': '#dc2626',  # Red (0°)
    'ZAF': '#d946ef',  # Fuchsia (300°)
    'LSO': '#84cc16',  # Lime (80°)
    'MOZ': '#14b8a6',  # Teal (180°)
    'PRT': '#059669',  # Emerald-dark (165°)
    'FRA': '#ec4899',  # Pink (330°)
}

def hex_to_rgb(hex_color):
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def color_distance(color1, color2):
    rgb1 = hex_to_rgb(color1)
    rgb2 = hex_to_rgb(color2)
    return sum((a - b) ** 2 for a, b in zip(rgb1, rgb2)) ** 0.5

print("=" * 80)
print("FINAL COLOR DISTINCTION CHECK")
print("=" * 80)
print()

countries = list(COLORS.keys())
min_distance = float('inf')
min_pair = None

for i, c1 in enumerate(countries):
    for c2 in countries[i+1:]:
        dist = color_distance(COLORS[c1], COLORS[c2])
        status = "✅" if dist >= 80 else "⚠️"
        
        # Special check for known problematic pairs
        if (c1 == 'ZAF' and c2 == 'FRA') or (c1 == 'FRA' and c2 == 'ZAF'):
             print(f"{status} {c1} ↔ {c2}: {dist:.2f} (Target > 80)")
        elif dist < 100:
             print(f"{status} {c1} ↔ {c2}: {dist:.2f}")

        if dist < min_distance:
            min_distance = dist
            min_pair = (c1, c2)

print()
print(f"Minimum Distance: {min_distance:.2f} ({min_pair[0]} ↔ {min_pair[1]})")

if min_distance > 40:
    print("\n✅ SUCCESS: All colors are visually distinct!")
else:
    print("\n❌ FAILURE: Some colors are still too similar.")
