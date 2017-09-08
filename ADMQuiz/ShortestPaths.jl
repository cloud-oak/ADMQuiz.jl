module ShortestPaths
push!(LOAD_PATH, dirname(@__FILE__))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using ADMStructures
using MoodleQuiz
using TikzPictures
using MoodleTools

export Mode, DijkstraFail, TwoPaths, None
@enum Mode DijkstraFail TwoPaths None

export unique_shortestpaths!, dijkstra, rating_dijkstra 
function bellman_ford(G::Graph, c; root=1, edge_subset=G.E)
    label = Dict{Int, Float32}(v => Inf for v in G.V)
    label[root] = 0
    for _ in 1:length(G.V)
        for (i, j) in edge_subset
            if label[i] + c[i,j] < label[j]
                label[j] = label[i] + c[i, j]
            end
            label[j] = min(label[j], label[i] + c[i, j])
        end
    end
    return label
end

function dijkstra(G::Graph, c; root=1, depth=Inf)
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
                if dist[v] > dist[u] + c[u, v]
                    dist[v] = dist[u] + c[u, v]
                end
            end
        end
    end

    return dist
end

function rating_dijkstra(G::Graph, c; root=1, depth=Inf)
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
                if dist[v] < dist[u] + c[u, v]
                    num_left += 1
                elseif dist[v] > dist[u] + c[u, v]
                    num_changed += 1
                    dist[v] = dist[u] + c[u, v]
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

function unique_shortestpaths(G; root=1, dijkstra_fail=false, range_on_tree=1:8, offset_range=1:1)
    # Finde gewurzelten Spannbaum
    connected = Set([root])
    label = Dict{Int, Float32}(v => Inf for v in G.V)
    label[root] = 0
    T = Set()

    c = zeros(Int64, length(G.V), length(G.V))

    while length(connected) != length(G.V)
        for (i, j) in random_order(G.E) 
            if i in connected && !(j in connected)
                push!(T, (i, j))
                push!(connected, j)
                c[i, j] = rand(range_on_tree)
                label[j] = label[i] + c[i, j]
            end
        end
    end

    skip_edges = []

    if dijkstra_fail
        for (v, w) in random_order(setdiff(G.E, T))
            if label[v] > label[w]
                c[v, w] = label[w] - label[v] - rand(offset_range)

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
        c[i, j] = max(0, label[j] - label[i]) + rand(offset_range)
    end
    
    return T, c, label
end

export two_shortestpaths
function two_shortestpaths(G; s=1, t=-1, range_on_tree=1:8, offset_range=1:1)
    if t == -1
        t = G.V[end]
    end
    
    label = Dict{Int, Float32}(v => Inf for v in G.V)
    label[s] = 0
    c = zeros(Int64, length(G.V), length(G.V))

    need_ambiguity = true

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
                c[i, j] = rand(range_on_tree)
                label[j] = label[i] + c[i, j]
            end
        end
    end
    
    # We have one path already
    ambiguity = 1
    # Put the other edges back in
    for (i, j) in random_order(G.E)
        if (i, j) ∉ T
            if need_ambiguity && reachable(G, j, t) && label[j] ≥ label[i]
                # Für Dijkstra positive Kanten bewahren?
                need_ambiguity = false
                c[i, j] = label[j] - label[i]
            else
                c[i, j] = max(0, label[j] - label[i] + rand(offset_range))
            end
        end
    end
    
    return T, c, label
end

export all_paths
"""
A DFS that returns all s-t-Paths and their lengths
"""
function all_paths(G::Graph; c=nothing, s=1, t=-1)
    has_costs = c isa Dict

    if t == -1
        t = G.V[end]
    end
    if s == -1
        s = G.V[end]
    end

    q = [[s]]
    if has_costs
        costs = [0]
    end

    paths = []

    count = 0
    while !isempty(q)
        path = pop!(q)
        if has_costs
            cost = pop!(costs)
        end
        last = path[end]

        for (i, j) in G.E
            if (!G.directed && j == last)
                i, j = j, i
            end
            if i == last
                if j == t
                    if has_costs
                        push!(paths, (vcat(path, [t]), cost + c[i, j]))
                    else
                        push!(paths, vcat(path, [t]))
                    end
                elseif (j ∉ path)
                    push!(q, path ∪ [j])
                    if has_costs
                        push!(costs, cost + c[i, j])
                    end
                end
            end
        end
    end
    paths
end

export reachable
function reachable(G::Graph, s=1, t=-1)::Bool
    if t == -1
        t = G.V[end]
    end
    if s == -1
        s = G.V[end]
    end

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

export generateOnestepDijkstraQuestion
function generateOnestepDijkstraQuestion(G::Graph; range_on_tree=1:8, offset_range=1:1, minsteps=2, maxleft=3, max_iterations=100)
    allowed_depths = collect(minsteps:(length(G.V) - maxleft))
    ambiguous = true

    while ambiguous
        T, c, dist = unique_shortestpaths(G, range_on_tree=range_on_tree, offset_range=offset_range, dijkstra_fail=false)
        dist, rating, visited = rating_dijkstra(G, c, depth=rand(allowed_depths))

        next_node, next_uniq = argmin(setdiff(G.V, visited), by=dist, return_uniq=true)

        if !next_uniq
            continue
        else
            amiguous = false
        end

        num_changed = 0
        num_left = 0 

        new_dist = deepcopy(dist)

        for (i, v) in G.E
            if i == next_node
                if dist[v] <= dist[i] + c[i, v]
                    num_left += 1
                elseif dist[v] > dist[i] + c[i, v]
                    num_changed += 1
                    new_dist[v] = dist[i] + c[i, v]
                end
            end
        end

        G.labels = ["$l : $(dist[v] == Inf ? "\\infty" : dist[v])" for (l, v) in zip(G.labels, G.V)]
        dijkstra_img = graph_moodle(G, c, marked_nodes=visited)
        sp_labelling!(G)

        vector_answer = VectorEmbeddedAnswer(
            [new_dist[v] for v in G.V],
            labels=G.labels
        )

        return Question(EmbeddedAnswers,
            Name="Dijkstra Einzelschritt",
            Text=MoodleText("""
                Führen Sie im unten abgebildeten Graphen eine Iteration des Dijkstra-Algorithmus aus.
                (Geben Sie dabei den Wert \\(\\infty\\) als 'inf' ein.)
                <br />
                $(EmbedFile(dijkstra_img, width="12cm", height="8cm"))<br />
                $vector_answer
                """,
                MoodleQuiz.HTML, [dijkstra_img])
            )
    end
end

export generateDijkstraQuestion
function generateDijkstraQuestion(G::Graph; mode::Mode=None, range_on_tree=1:8, offset_range=1:1, minsteps=2, maxleft=3, max_iterations=100)
    T = []
    c = Dict()
    label = Dict()
    iterations = 0

    @label retry_generation
    if mode == DijkstraFail
        T, c, label = unique_shortestpaths(G, dijkstra_fail=true, range_on_tree=range_on_tree, offset_range=offset_range)
    elseif mode == TwoPaths
        T, c, label = two_shortestpaths(G, range_on_tree=range_on_tree, offset_range=offset_range)
    else
        T, c, label = uunique_shortestpaths(G, dijkstra_fail=false, range_on_tree=range_on_tree, offset_range=offset_range)
    end

    paths = all_paths(G, c)
    dist  = minimum(c for (p, c) in paths)
    correct_paths = [p for (p, c) in paths if c == dist]
    false_paths   = [p for (p, c) in paths if c != dist]

    right_answers = mode == TwoPaths ? 2 : 1
    false_answers = 4 - right_answers 

    answers = []                    
    for (i, p) in enumerate(correct_paths)
        if i > right_answers
            break
        end
        path = join([G.labels[v] for v in p], " \\rightarrow ")
        push!(answers, Answer("\\($path\\)", Correct=1))
    end
    
    for (i, p) in enumerate(false_paths)
        if i > false_answers
            break
        end
        path = join([G.labels[v] for v in p], " \\rightarrow ")
        push!(answers, Answer("\\($path\\)", Correct=0))
    end

    if length(answers) < right_answers + false_answers && iterations < max_iterations
        iterations += 1
        @goto retry_generation
    end

    img = graph_moodle(G, c)

    text = "Welche der folgenden Wege sind kürzeste \\(s\\)-\\(t\\)-Wege im abgebildeten Graphen?"

    return(Question(MultipleChoice,
            Name = "Kürzeste Wege",
            Text = MoodleText(
                join([text, EmbedFile(img, width="18cm")], "<br />\n"),
                MoodleQuiz.HTML, [img]
            ),
            Answers = answers
        ))
end

end

