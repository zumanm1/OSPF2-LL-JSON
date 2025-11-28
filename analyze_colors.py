import colorsys

# Current color assignments
COLORS = {
    'ZWE': '#10b981',  # Emerald
    'USA': '#3b82f6',  # Blue
    'DEU': '#f59e0b',  # Amber
    'GBR': '#ef4444',  # Red
    'ZAF': '#a855f7',  # Purple
    'LSO': '#a3e635',  # Lime-Light
    'MOZ': '#0ea5e9',  # Sky
    'PRT': '#22c55e',  # Green
    'FRA': '#8b5cf6',  # Violet
}

def hex_to_rgb(hex_color):
    """Convert hex to RGB"""
    hex_color = hex_color.lstrip('#')
    return tuple(int(hex_color[i:i+2], 16) for i in (0, 2, 4))

def rgb_to_hsv(rgb):
    """Convert RGB to HSV"""
    r, g, b = [x / 255.0 for x in rgb]
    return colorsys.rgb_to_hsv(r, g, b)

def color_distance(color1, color2):
    """Calculate perceptual color distance"""
    rgb1 = hex_to_rgb(color1)
    rgb2 = hex_to_rgb(color2)
    
    # Euclidean distance in RGB space
    return sum((a - b) ** 2 for a, b in zip(rgb1, rgb2)) ** 0.5

def analyze_colors():
    """Analyze color similarity"""
    print("=" * 80)
    print("COLOR SIMILARITY ANALYSIS")
    print("=" * 80)
    print()
    
    countries = list(COLORS.keys())
    
    # Find similar colors
    print("🔍 SIMILAR COLOR PAIRS (Distance < 100):")
    print()
    
    similar_pairs = []
    for i, c1 in enumerate(countries):
        for c2 in countries[i+1:]:
            dist = color_distance(COLORS[c1], COLORS[c2])
            if dist < 100:
                similar_pairs.append((c1, c2, dist))
                print(f"⚠️  {c1} ({COLORS[c1]}) ↔ {c2} ({COLORS[c2]})")
                print(f"   Distance: {dist:.2f} (TOO SIMILAR!)")
                print()
    
    if not similar_pairs:
        print("✓ No similar color pairs found")
    
    print("=" * 80)
    print("HSV ANALYSIS")
    print("=" * 80)
    print()
    
    for country, hex_color in COLORS.items():
        rgb = hex_to_rgb(hex_color)
        h, s, v = rgb_to_hsv(rgb)
        print(f"{country}: {hex_color}")
        print(f"   RGB: {rgb}")
        print(f"   HSV: H={h*360:.1f}° S={s*100:.1f}% V={v*100:.1f}%")
        print()
    
    return similar_pairs

if __name__ == "__main__":
    similar = analyze_colors()
    
    print("=" * 80)
    print("RECOMMENDATIONS")
    print("=" * 80)
    print()
    
    if similar:
        print("🔧 CRITICAL: Fix these similar color pairs:")
        for c1, c2, dist in similar:
            print(f"   • {c1} and {c2} (distance: {dist:.2f})")
        print()
        print("Suggested fixes:")
        print("   • Change FRA from #8b5cf6 (violet) to #ec4899 (pink)")
        print("   • Or change ZAF from #a855f7 (purple) to #f97316 (orange)")
    else:
        print("✓ All colors are sufficiently distinct")
