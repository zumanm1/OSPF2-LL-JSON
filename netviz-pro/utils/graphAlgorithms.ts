import { NetworkNode, NetworkLink, PathResult } from '../types';

// Adjacency list type: NodeID -> Array of { targetId, cost, linkIndex }
type AdjacencyList = Map<string, Array<{ target: string; cost: number; linkIndex: number }>>;

const buildAdjacencyList = (nodes: NetworkNode[], links: NetworkLink[]): AdjacencyList => {
  const adj = new Map<string, Array<{ target: string; cost: number; linkIndex: number }>>();
  
  nodes.forEach(node => adj.set(node.id, []));

  links.forEach((link, index) => {
    const sourceId = typeof link.source === 'object' ? (link.source as NetworkNode).id : link.source as string;
    const targetId = typeof link.target === 'object' ? (link.target as NetworkNode).id : link.target as string;

    // Use forward_cost for forward direction, fallback to legacy cost for backward compatibility
    const forwardCost = link.forward_cost !== undefined ? link.forward_cost : (link.cost || 1);
    const reverseCost = link.reverse_cost !== undefined ? link.reverse_cost : forwardCost;

    // Add Forward Edge
    if (adj.has(sourceId)) {
      adj.get(sourceId)?.push({ target: targetId, cost: forwardCost, linkIndex: index });
    }

    // Add Reverse Edge (with correct reverse cost for asymmetric routing)
    if (adj.has(targetId)) {
       adj.get(targetId)?.push({ target: sourceId, cost: reverseCost, linkIndex: index });
    }
  });

  return adj;
};

// MinHeap implementation for efficient Dijkstra
class MinHeap {
  private heap: { id: string; cost: number }[] = [];

  push(item: { id: string; cost: number }): void {
    this.heap.push(item);
    this.bubbleUp(this.heap.length - 1);
  }

  pop(): { id: string; cost: number } | undefined {
    if (this.heap.length === 0) return undefined;
    const result = this.heap[0];
    const last = this.heap.pop()!;
    if (this.heap.length > 0) {
      this.heap[0] = last;
      this.bubbleDown(0);
    }
    return result;
  }

  isEmpty(): boolean {
    return this.heap.length === 0;
  }

  private bubbleUp(index: number): void {
    while (index > 0) {
      const parentIndex = Math.floor((index - 1) / 2);
      if (this.heap[parentIndex].cost <= this.heap[index].cost) break;
      [this.heap[parentIndex], this.heap[index]] = [this.heap[index], this.heap[parentIndex]];
      index = parentIndex;
    }
  }

  private bubbleDown(index: number): void {
    const length = this.heap.length;
    while (true) {
      const leftChild = 2 * index + 1;
      const rightChild = 2 * index + 2;
      let smallest = index;

      if (leftChild < length && this.heap[leftChild].cost < this.heap[smallest].cost) {
        smallest = leftChild;
      }
      if (rightChild < length && this.heap[rightChild].cost < this.heap[smallest].cost) {
        smallest = rightChild;
      }
      if (smallest === index) break;
      [this.heap[index], this.heap[smallest]] = [this.heap[smallest], this.heap[index]];
      index = smallest;
    }
  }
}

export const findShortestPathCost = (
  nodes: NetworkNode[],
  links: NetworkLink[],
  startNodeId: string,
  endNodeId: string
): number => {
  if (startNodeId === endNodeId) return 0;

  const adj = buildAdjacencyList(nodes, links);
  const costs = new Map<string, number>();
  const pq = new MinHeap();

  nodes.forEach(node => costs.set(node.id, Infinity));
  costs.set(startNodeId, 0);
  pq.push({ id: startNodeId, cost: 0 });

  while (!pq.isEmpty()) {
    // CRITICAL FIX: Use proper MinHeap instead of O(n log n) sort per iteration
    const current = pq.pop()!;
    const { id: currentId, cost: currentCost } = current;

    if (currentCost > (costs.get(currentId) || Infinity)) continue;
    if (currentId === endNodeId) return currentCost;

    const neighbors = adj.get(currentId) || [];
    for (const neighbor of neighbors) {
      // CRITICAL FIX: Skip negative costs to prevent incorrect results
      // (Dijkstra requires non-negative edge weights)
      if (neighbor.cost < 0) {
        console.warn(`[Dijkstra] Skipping negative cost edge: ${currentId} -> ${neighbor.target} (cost: ${neighbor.cost})`);
        continue;
      }
      const newCost = currentCost + neighbor.cost;
      if (newCost < (costs.get(neighbor.target) || Infinity)) {
        costs.set(neighbor.target, newCost);
        pq.push({ id: neighbor.target, cost: newCost });
      }
    }
  }

  return Infinity;
};

export const findAllPaths = (
  nodes: NetworkNode[],
  links: NetworkLink[],
  startNodeId: string,
  endNodeId: string,
  limit: number = 50
): PathResult[] => {
  const adj = buildAdjacencyList(nodes, links);
  const results: PathResult[] = [];
  
  // DFS State
  const stack: { 
    currentNode: string; 
    pathNodes: string[]; 
    pathLinks: number[]; 
    currentCost: number;
  }[] = [];

  stack.push({
    currentNode: startNodeId,
    pathNodes: [startNodeId],
    pathLinks: [],
    currentCost: 0
  });

  while (stack.length > 0) {
    const { currentNode, pathNodes, pathLinks, currentCost } = stack.pop()!;

    if (currentNode === endNodeId) {
      results.push({
        id: `${startNodeId}-${endNodeId}-${results.length}`,
        nodes: pathNodes,
        links: pathLinks,
        totalCost: currentCost,
        hopCount: pathNodes.length - 1
      });

      if (results.length >= limit) break;
      continue;
    }

    const neighbors = adj.get(currentNode) || [];
    
    // Sort neighbors by cost to explore cheaper paths first (greedy-ish DFS)
    neighbors.sort((a, b) => b.cost - a.cost); // Stack is LIFO, so push high cost first to pop low cost first

    for (const neighbor of neighbors) {
      // Avoid cycles
      if (!pathNodes.includes(neighbor.target)) {
        stack.push({
          currentNode: neighbor.target,
          pathNodes: [...pathNodes, neighbor.target],
          pathLinks: [...pathLinks, neighbor.linkIndex],
          currentCost: currentCost + neighbor.cost
        });
      }
    }
  }

  // Sort results by cost, then hop count
  return results.sort((a, b) => {
    if (a.totalCost !== b.totalCost) return a.totalCost - b.totalCost;
    return a.hopCount - b.hopCount;
  });
};