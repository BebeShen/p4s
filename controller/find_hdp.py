from collections import deque

def find_paths(graph, start_nodes, end_nodes):
    queue = deque([(node, [node]) for node in start_nodes])
    visited = set()
    paths = []

    while queue:
        node, path = queue.popleft()
        visited.add(node)

        for neighbor in graph[node]:
            if neighbor in end_nodes:
                paths.append(path + [neighbor])
            elif neighbor not in visited:
                queue.append((neighbor, path + [neighbor]))

    return paths

# Given graph(topo3)
#
#        B---D
#       / \ / \
#  s---A   X   F---t 
#       \ / \ / 
#        C---E
#


graph = {
    'A': ['B', 'C'],
    'B': ['A', 'D', 'E'],
    'C': ['A', 'D', 'E'],
    'D': ['B', 'C', 'F'],
    'E': ['B', 'C', 'F'],
    'F': ['D', 'E']
}


start_nodes = ['B', 'C']
end_nodes = ['D', 'E']

paths = find_paths(graph, start_nodes, end_nodes)
print(paths)