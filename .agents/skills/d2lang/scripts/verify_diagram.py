import sys
import xml.etree.ElementTree as ET

def verify(svg_path):
    try:
        # Parse SVG to find viewBox
        tree = ET.parse(svg_path)
        root = tree.getroot()
        viewbox_str = root.attrib.get('viewBox')
        if not viewbox_str:
            print("ERROR: viewBox attribute not found in SVG.")
            return False
        
        parts = viewbox_str.split()
        if len(parts) != 4:
            print(f"ERROR: Invalid viewBox format: {viewbox_str}")
            return False
        
        min_x, min_y, width, height = map(float, parts)
        aspect_ratio = width / height
        print(f"SVG Dimensions: {width} x {height}")
        print(f"Computed Aspect Ratio (Width/Height): {aspect_ratio:.3f}")
        
        # Check aspect ratio
        if aspect_ratio < 0.4:
            print("WARNING: Diagram is extremely TALL and NARROW (vertical strip).")
            print("Action: Consider using 'direction: right' or nested stage containers to distribute elements horizontally.")
            return False
        elif aspect_ratio > 3.0:
            print("WARNING: Diagram is extremely WIDE and SHORT (horizontal strip).")
            print("Action: Consider using 'direction: down' or wrapping elements to stack them vertically.")
            return False
        else:
            print("SUCCESS: Diagram dimensions and aspect ratio look balanced.")
            return True
    except Exception as e:
        print(f"ERROR: Failed to parse SVG file: {e}")
        return False

if __name__ == '__main__':
    if len(sys.argv) < 2:
        print("Usage: python3 verify_diagram.py <path_to_svg>")
        sys.exit(1)
    
    success = verify(sys.argv[1])
    sys.exit(0 if success else 1)
