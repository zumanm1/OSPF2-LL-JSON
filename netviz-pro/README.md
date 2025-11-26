# NetViz Pro

**OSPF Network Topology Visualizer** - A powerful tool for visualizing and analyzing OSPF network topologies with 14 analysis modals.

## Quick Installation (Any Machine)

```bash
# Clone the repository
git clone https://github.com/zumanm1/OSPF2-LL-JSON.git
cd OSPF2-LL-JSON/netviz-pro

# Install dependencies
npm install

# Start the application
npm run dev
```

Open: **http://localhost:9040** (or your server IP:9040)

## System Requirements

- **Node.js** v18.0.0+ (required)
- **npm** v9.0.0+ (comes with Node.js)
- Modern browser (Chrome, Firefox, Safari, Edge)

### Install Node.js on Ubuntu/Debian

```bash
# Update package list
sudo apt update

# Install Node.js 18+ via NodeSource
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Verify installation
node --version  # Should show v20.x.x
npm --version   # Should show 10.x.x
```

### Install Node.js on CentOS/RHEL

```bash
curl -fsSL https://rpm.nodesource.com/setup_20.x | sudo bash -
sudo yum install -y nodejs
```

### Install Node.js on macOS

```bash
brew install node@20
```

## Features (14 Analysis Modals)

| Modal | Description |
|-------|-------------|
| **Pair Countries** | Compare paths between country pairs |
| **Impact Analysis** | Analyze link change impact |
| **Transit Analyzer** | Identify transit countries |
| **What-If Scenario** | Simulate cost/status changes |
| **Full Cost Matrix** | View all country-pair costs |
| **Dijkstra Visualizer** | Step-by-step algorithm visualization |
| **Traffic Flow** | Link utilization analysis |
| **Cost Optimizer** | Optimization recommendations |
| **Ripple Effect** | Chain reaction analysis |
| **Network Health** | Health score and bottlenecks |
| **Capacity Planning** | Bandwidth planning |
| **Utilization Matrix** | Traffic utilization heatmap |
| **Pre/Post Traffic** | Before/after comparison |
| **Interface Dashboard** | Interface-level details |

## Export Features

- **Export CSV** button on each modal
- **Export All** button in header - exports comprehensive analysis

## Tech Stack

- React 19 + TypeScript
- D3.js v7 (visualization)
- Vite (build tool)
- Tailwind CSS (styling)
- Lucide Icons

## Project Structure

```
netviz-pro/
├── App.tsx                 # Main application
├── components/             # React components (14 modals)
│   ├── NetworkGraph.tsx    # D3 visualization
│   ├── FileUpload.tsx      # File handler
│   ├── *Modal.tsx          # Analysis modals
│   └── InterfaceCapacityDashboard.tsx
├── utils/                  # Utilities
│   ├── parser.ts           # JSON parser
│   ├── graphAlgorithms.ts  # Dijkstra, paths
│   ├── exportUtils.ts      # CSV export functions
│   └── impactAnalysis.ts   # Impact calculations
├── context/                # React contexts
│   └── ThemeContext.tsx    # Dark/Light theme
├── types.ts                # TypeScript interfaces
└── constants.ts            # Country colors, defaults
```

## Input File Format

Minimum required JSON structure:

```json
{
  "nodes": [
    {"id": "R1", "label": "Router1", "country": "USA"},
    {"id": "R2", "label": "Router2", "country": "Germany"}
  ],
  "links": [
    {
      "source": "R1",
      "target": "R2",
      "forward_cost": 10,
      "reverse_cost": 10,
      "status": "up"
    }
  ]
}
```

## Running in Production

```bash
# Build for production
npm run build

# Preview production build locally
npm run preview

# Or serve with any static server
npx serve dist
```

## Running on Remote Server

To make the app accessible from other machines:

```bash
# The app already binds to 0.0.0.0:9040
npm run dev

# Access from any machine on the network:
# http://<server-ip>:9040
```

## Troubleshooting

### Port already in use
```bash
# Kill process on port 9040
lsof -ti:9040 | xargs kill -9
```

### npm install fails
```bash
# Clear npm cache and retry
npm cache clean --force
rm -rf node_modules package-lock.json
npm install
```

### App shows blank screen
- Check browser console for errors
- Ensure you've uploaded a valid JSON topology file

## License

MIT
