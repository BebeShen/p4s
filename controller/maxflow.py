from collections import deque, defaultdict
import math

class Graph:
    def __init__(self, vertices):
        self.V = vertices
        self.graph = defaultdict(lambda: defaultdict(int))
    
    def add_edge(self, u, v, w=1):
        self.graph[u][v] = w
    
    def bfs(self, s, t, parent):
        # BFS to find disjoint path
        visited = [False] * self.V
        queue = deque()
        
        queue.append(s)
        visited[s] = True
        
        while queue:
            u = queue.popleft()
            for v in self.graph[u]:
                if not visited[v] and self.graph[u][v] > 0:
                    queue.append(v)
                    visited[v] = True
                    parent[v] = u
        
        return visited[t]
    
    def ford_fulkerson(self, source, sink):
        # init
        parent = [-1] * self.V
        max_flow = 0
        paths = []
        
        while self.bfs(source, sink, parent):
            path_flow = float("Inf")
            s = sink
            path = []
            
            # 找出路徑並記錄最小流量
            while s != source:
                path.append(s)
                path_flow = min(path_flow, self.graph[parent[s]][s])
                s = parent[s]
            path.append(source)
            path.reverse()
            paths.append(path)
            
            # 更新圖
            v = sink
            while v != source:
                u = parent[v]
                self.graph[u][v] -= path_flow
                self.graph[v][u] += path_flow
                v = parent[v]
            
            max_flow += path_flow
        # print(max_flow, paths)
        return max_flow, paths

def find_disjoint_paths(edges, vertices, source, sink):
    """
    找出頂點不相交的s-t路徑
    
    arguments:
    edges: 邊的列表，格式為 [(u, v), ...]
    vertices: 節點數量
    source: 起點
    sink: 終點
    
    returns:
    paths: 不相交路徑的列表
    """
    g = Graph(vertices * 2)
    
    # 為每個頂點創建入點和出點
    for i in range(vertices):
        if i != source and i != sink:
            g.add_edge(i*2, i*2+1, 1)  # Unit-capacity
    
    for u, v in edges:
        g.add_edge(u*2+1, v*2, 1)
    
    source_out = source*2+1
    sink_in = sink*2
    
    # calculate max_flow
    max_flow, paths = g.ford_fulkerson(source_out, sink_in)
    
    # 轉換路徑格式
    real_paths = []
    for path in paths:
        real_path = []
        for node in path:
            real_node = node // 2
            if real_node not in real_path:
                real_path.append(real_node)
        real_paths.append(real_path)
    
    return real_paths

if __name__ == "__main__":

    ### k5,5
    # edges = [(0,1), (0,2), (0,3), (0,4), (1,2), (1,3), (1,4), (2,3), (2,4), (3,4)]
    ### topo1
    edges = [(0,1), (0,2), (1,5), (2,3), (2,4), (3,5), (4,5)]
    ### topo2
    # edges = [(0,1), (0,2), (1,3), (1,4), (2,3), (2,4), (1,4), (3,5), (4,5)]

    vertices = 6
    source = 0
    sink = 5
    
    paths = find_disjoint_paths(edges, vertices, source, sink)

    ### topo1
    # hp_list = [[2, 4, 5]] 
    ### topo2
    hp_list = [[1, 4], [2, 3]]

    for hp in hp_list:
        hdp = hp
        for p in paths:
            if hp[0] in p:
                front_index = p.index(hp[0])
                hdp = p[0:front_index] + hdp
            
            if hp[-1] in p:
                back_index = p.index(hp[-1])
                hdp = hdp + p[back_index+1:]
        print(hdp)
        
        paths.append(hdp)

    # print(paths)
    print("Hierarchical Disjoint Paths：")
    for i, path in enumerate(paths, 1):
        print(f"路徑 {i}: {' -> '.join(map(str, path))}")