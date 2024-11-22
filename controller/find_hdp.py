from collections import deque

def find_paths(graph, start_nodes_set, end_nodes_set):
    queue = deque([(node, [node]) for node in start_nodes_set])
    visited = set()
    paths = []

    while queue:
        node, path = queue.popleft()
        visited.add(node)

        for neighbor in graph[node]:
            if neighbor in end_nodes_set:
                paths.append(path + [neighbor])
            elif neighbor not in visited:
                queue.append((neighbor, path + [neighbor]))

    return paths

# Given graph(topo2)
#
#        B---D
#       / \ / \
#  s---A   X   F---t 
#       \ / \ / 
#        C---E
#


graph = {
    'A': ['B', 'C'],
    'B': ['A', 'C', 'D', 'E'],
    'C': ['A', 'B', 'D', 'E'],
    'D': ['B', 'C', 'F'],
    'E': ['B', 'C', 'F'],
    'F': ['D', 'E']
}


start_nodes_set = ['B', 'C']
end_nodes_set = ['D', 'E']

paths = find_paths(graph, start_nodes_set, end_nodes_set)
print(paths)