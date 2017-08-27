module ShortestPaths

export unique_shortestpaths!, dijkstra, rating_dijkstra 

using ADMStructures
using MoodleQuiz
using TikzPictures
using MoodleTools

function bellman_ford(G::Graph; root=1, edge_subset=G.E)
    label = Dict{Int, Float32}(v => Inf for v in G.V)
    label[root] = 0
    for _ in 1:length(G.V)
        for (i, j) in edge_subset
            if label[i] + G.c[i,j] < label[j]
                label[j] = label[i] + G.c[i, j]
            end
            label[j] = min(label[j], label[i] + G.c[i, j])
        end
    end
    return label
end

function dijkstra(G::Graph; root=1, depth=Inf)
    # dist: The distance of root -> v
    dist = Dict{Any, Any}()
    
    for v in G.V
        dist[v] = Inf
    end

    dist[root] = 0
    
    S = Set()
    
    iterations = min(length(G.V), depth)

    while length(S) < iterations
        u = argmin(setdiff(G.V, S), by=dist)
        push!(S, u)
        for (i, v) in G.E
            if i == u
                if dist[v] > dist[u] + G.c[u, v]
                    dist[v] = dist[u] + G.c[u, v]
                end
            end
        end
    end

    return dist
end

function rating_dijkstra(G::Graph; root=1, depth=Inf)
    # rating variables
    completely_unique = true
    num_changed = 0
    num_same = 0
    num_left = 0
    
    # dist: The distance of root -> v
    dist = Dict{Any, Any}()
    # edge_dist: The length of root -> v in edges
    edge_dist = Dict{Any, Any}()
    
    for v in G.V
        dist[v] = Inf
        edge_dist[v] = Inf
    end
    dist[root] = 0
    edge_dist[root] = 0
    
    S = Set()
    Q = Set(G.V)
    
    while !isempty(Q) && length(S) < depth
        u, uniq = argmin(Q, by=dist, return_uniq=true)
        completely_unique &= uniq
        push!(S, u)
        delete!(Q, u)
        for (i, v) in G.E
            if i == u
                if dist[v] < dist[u] + G.c[u, v]
                    num_left += 1
                elseif dist[v] > dist[u] + G.c[u, v]
                    num_changed += 1
                    dist[v] = dist[u] + G.c[u, v]
                    edge_dist[v] = edge_dist[u] + 1
                else
                    num_same += 1
                end
            end
        end
    end
    return dist, Dict(
        "Algorithmus eindeutig" => completely_unique,
        "Anzahl geändert" => num_changed,
        "Anzahl gelassen" => num_left,
        "Anzahl egal" => num_same,
        "s-t-Kanten" => edge_dist[length(G.V)]
    ), S
end

function unique_shortestpaths!(G; root=1, dijkstra_fail=false, path_range=1:8, offset_range=1:1)
    # Finde gewurzelten Spannbaum
    connected = Set([root])
    label = Dict{Int, Float32}(v => Inf for v in G.V)
    label[root] = 0
    T = Set()

    while length(connected) != length(G.V)
        for (i, j) in random_order(G.E) 
            if i in connected && !(j in connected)
                push!(T, (i, j))
                push!(connected, j)
                G.c[i, j] = rand(path_range)
                label[j] = label[i] + G.c[i, j]
            end
        end
    end

    skip_edges = []

    if dijkstra_fail
        for (v, w) in random_order(setdiff(G.E, T))
            if label[v] > label[w]
                G.c[v, w] = label[w] - label[v] - rand(offset_range)

                # Alten parent von w löschen
                for (a, b) in T
                    if (b == w)
                        push!(skip_edges, (a, b))
                        delete!(T, (a, b))
                    end
                end
                push!(T, (v, w))
                label = bellman_ford(G, root=root, edge_subset=T)
                break
            end
        end
    end

    for (i, j) in G.E
        if (i, j) in union(T, skip_edges)
            continue
        end
        G.c[i, j] = max(0, label[j] - label[i]) + rand(offset_range)
    end
    
    return T, label
end


export multiple_st_paths!
function multiple_st_paths!(G; s=1, t=-1, num_ambiguities=2)
    if t == -1
        t = G.V[end]
    end
    
    label = Dict{Int, Float32}(v => Inf for v in G.V)
    label[s] = 0

    # Finde Arboreszenz
    T = Set()
    connected = Set([s])
    while length(connected) != length(G.V)
        for (i, j) in random_order(G.E)
            # Füge Kante hinzu, wenn sie einen neuen Knoten erschließt
            if i in connected && !(j in connected)
                push!(T, (i, j))
                push!(connected, j)
                # Zufällige Kosten für Kanten auf KWA
                G.c[i, j] = rand(1:5)
                label[j] = label[i] + G.c[i, j]
            end
        end
    end
    
    # We have one path already
    ambiguity = 1
    # Put the other edges back in
    for (i, j) in random_order(G.E)
        if (i, j) ∉ T
            if ambiguity < num_ambiguities && reachable(G, j, t) && label[j] ≥ label[i]
                # TODO: Für Dijkstra positive Kanten bewahren?
                ambiguity += 1
                G.c[i, j] = label[j] - label[i]
            else
                G.c[i, j] = max(0, label[j] - label[i] + 1)
            end
        end
    end
    
    return T
end

export all_paths
"""
A DFS that returns all s-t-Paths and their lengths
"""
function all_paths(G::Graph, s=1, t=-1)
    if t == -1
        t = G.V[end]
    end

    q = [[s]]
    costs = [0]

    paths = []

    count = 0
    while !isempty(q)
        path = pop!(q)
        cost = pop!(costs)
        last = path[end]

        for (i, j) in G.E
            if i == last
                if j == t
                    push!(paths, (path ∪ [t], cost + G.c[i, j]))
                elseif (j ∉ path) || (s == t == j) # Keine Kreise außer s=t
                    push!(q, path ∪ [j])
                    push!(costs, cost + G.c[i, j])
                end
            end
        end
    end
    paths
end

export reachable
function reachable(G::Graph, s, t)::Bool
    connected = Set([s])
    changed = true
    while changed
        changed = false
        for (i, j) in G.E
            if i ∈ connected && j ∉ connected
                changed = true
                push!(connected, j)
            end
        end
    end
    return (t ∈ connected)
end
end