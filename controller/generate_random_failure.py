from collections import Counter
import random
import json

if __name__ == "__main__":
    # Topo3
    edges = [(0,1), (0,2), (1,3), (1,4), (2,3), (2,4), (3,5), (4,5)]
    vertices = 6
    source = 0
    sink = 5

    failure_list = []

    count = 100
    while count != 0:
        f = random.sample(edges, k=2)
        if ((0,1) in f and (0,2) in f) or ((3,5) in f and (4,5) in f):
            print("ffffff", f)
        else:
            failure_list.append(f)
            count -= 1

    pair_counts = {}
    for pair in failure_list:
        pair_counts[tuple(sorted(pair))] = pair_counts.get(tuple(sorted(pair)), 0) + 1

    sorted_result = sorted(pair_counts.items(), key=lambda x: (x[0][0], x[0][1]))
    
    with open('m_failure_100.txt', 'w') as f:
        for pair, count in sorted_result:
        # for pair, count in pair_counts.items():
            f.write(f"{pair} : {count}\n")
            print(f"Pair {pair} occurred {count} times.")
    # print(pair_counts)
    # print(sorted_result)
    
