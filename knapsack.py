import numpy as np

# Generiere Knapsack-Instanzen
def generate_knapsack(number = 100, m = 5, c = 10, weight_range = (1, 10), profit_range = (1, 10), greedy_check=False):
    instances = []

    # Generiere so lange, bis gewünschte Anzahl an Instanzen erreicht ist
    while len(instances) < number:
        invalid = True
        while invalid:
        	# Gewichte und Nutzen zufällig generieren
            w = np.random.randint(*weight_range, m)
            p = np.random.randint(*profit_range, m)

            # Vorwärtsrekursion, die die Eindeutigkeit mit bestimmt
            ambiguous_nodes = set()
            A = np.zeros((m+1, c+1))
            parent = dict()
            A[0,1:] = -np.inf

            for k in range(1, m + 1):
                for l in range(c + 1):
                    current = (k, l)
                    leave   = (k-1, l)
                    take    = (k-1, l - w[k-1])

                    if l >= w[k-1]:
                        A[current] = max(A[leave], A[take] + p[k-1])
                        if(A[leave] >= A[take]):
                            parent[current] = leave
                        else:
                            parent[current] = take
                        if not np.isinf(A[current]):
                            if (A[leave] > A[take] + p[k-1] and leave in ambiguous_nodes) \
                            or (A[leave] < A[take] + p[k-1] and take in ambiguous_nodes) \
                            or (A[leave] == A[take] + p[k-1]):
                                ambiguous_nodes.add(current)
                    else:
                        A[current] = A[leave]
                        parent[current] = leave
                        if leave in ambiguous_nodes:
                            ambiguous_nodes.add(current)
            invalid = False
            
            optimal_value = A[m, :].max()
            
            if (A[m, :] == A[m, :].max()).sum() > 1 \
            or (m, A[m, :].argmax()) in ambiguous_nodes:
                invalid = True
            
            if greedy_check:        
                greedy_weight = 0
                greedy_value = 0
                # Greedy
                for i, (weight, profit) in enumerate(sorted(zip(w, p), key=lambda e: -e[1])):
                    if greedy_weight + weight <= c:
                        greedy_solution.append(i)
                        greedy_weight += weight
                        greedy_value += profit
                if(greedy_value == optimal_value):
                    invalid = True
        
        current_node = ((m, A[m, :].argmax()))
        knapsack_solution = []
        while current_node in parent:
            parent_node = parent[current_node]
            if current_node[1] != parent_node[1]:
                knapsack_solution.append(current_node[0])
            current_node = parent_node

        instances.append(dict(weights = w, profits = p, solution = sorted(knapsack_solution), value = optimal_value, capacity = int(c)))
    return instances
