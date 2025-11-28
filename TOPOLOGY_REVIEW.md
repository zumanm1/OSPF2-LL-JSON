# Topology Review: netviz-pro-topo-extra layers.json

## Overview
This topology has been expanded to 100 routers, incorporating existing nodes and adding 5 new countries.

## Node Distribution
- **Total Nodes**: 100
- **Existing Countries**:
  - ZWE: 4 nodes
  - USA: 2 nodes
  - DEU: 2 nodes
  - GBR: 2 nodes
- **New Countries**:
  - ZAF (South Africa): 24 nodes
  - MOZ (Mozambique): 17 nodes
  - FRA (France): 17 nodes
  - LSO (Lesotho): 16 nodes
  - PRT (Portugal): 16 nodes

## South Africa Dominance
South Africa (ZAF) has 24 nodes, which is approximately **41-50% more** than any other new country (16-17 nodes), satisfying the requirement of "40% more routers".

## Connectivity
- **Intra-country**: Ring topology with random cross-links for robustness.
- **Inter-country**:
  - New countries are connected in a ring (ZAF-LSO-MOZ-PRT-FRA-ZAF).
  - New countries are connected to existing countries to ensure a single connected component.
  - Specific links added:
    - ZAF <-> ZWE
    - PRT <-> DEU
    - FRA <-> GBR
    - USA <-> PRT
    - MOZ <-> ZAF
    - LSO <-> ZAF

## IP Addressing
- **Existing**: 172.16.x.x
- **New**: 172.16.100.x - 172.16.189.x (Unique Loopback IPs assigned)

## Application Enhancements
1.  **Load Large Topology**: A new button in the header allows loading this 100-node topology instantly.
2.  **View Modes**:
    - **Detailed View**: Shows all 100 nodes.
    - **High Level View**: Aggregates nodes by country, showing a simplified diagram with inter-country links.
3.  **Focus & Zoom**:
    - Selecting countries in the sidebar now **auto-zooms** to fit the selected nodes.
    - Unselected nodes are **dimmed** rather than hidden, preserving context.
4.  **Simulation Control**:
    - Added a **Pause/Resume** button to freeze the layout for easier analysis.
