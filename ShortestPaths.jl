module ShortestPaths

export unique_shortestpaths!, dijkstra, rating_dijkstra, generateFullDijkstraExcercises, sp_labelling!, generateOnestepDijkstraExcercises

using ADMStructures
using MoodleQuiz
using TikzPictures
using MoodleTools

"""
    Labels the vertices so that it is useful for shortest paths.
    The first vertex is labelled "s", the last vertex "t".
    All other vertices are labelled "v_i"
"""
function sp_labelling!(G::Graph)
    G.labels = ["v_{$(i-1)}" for (i, v) in enumerate(G.V)]
    G.labels[1] = "s"
    G.labels[end] = "t"
end

function unique_shortestpaths!(G; root=1, wanted_edges=[])
    # Finde gewurzelten Spannbaum
    randomedges = G.E[randperm(length(G.E))]
    connected = Set([root])
    T = wanted_edges
    for (i, j) in wanted_edges
        push!(connected, j)
    end
    label = Dict{Int, Float32}(v => Inf for v in G.V)
    label[root] = 0
    while length(connected) != length(G.V)
        for (i, j) in randomedges
            if i in connected && !(j in connected)
                push!(T, (i, j))
                push!(connected, j)
                G.c[i, j] = rand(1:5)
            end
        end
    end
    for _ in 1:length(G.V)
        # relax edges, a cheap Bellman-Ford
        for (i, j) in T
            if label[i] + G.c[i,j] < label[j]
                label[j] = label[i] + G.c[i, j]
            end
            label[j] = min(label[j], label[i] + G.c[i, j])
        end
    end
    for (i, j) in G.E
        if (i, j) in T
            continue
        end
        G.c[i, j] = max(0, label[j] - label[i]) + 1
    end
    
    return T, label
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

function generateFullDijsktraExcercises(G::Graph; number::Int=30)
    G.positions = spring_positions(G, springlength=0)
    G.directed = true
    sp_labelling!(G)
    get_label = Dict((v, label) for (v, label) in zip(G.V, G.labels))

    instances = []
    paths = Set([])

    for i in 1:(2 * number)
        T, _ = unique_shortestpaths!(G)

        current = G.V[end]
        path = [get_label[current]]
        while current != G.V[1]
            for (i, j) in T
                if j == current
                    current = i
                    push!(path, get_label[i])
                end
            end
        end
        # reverse the path
        path = path[end:-1:1]
        push!(paths, path)
        push!(instances, (deepcopy(G), path))
    end

    function rating_function(instance)
        g, path = instance
        metrics = rating_dijkstra(g)[2]
        return metrics["Anzahl geändert"] + 3 * metrics["s-t-Kanten"] - 1000 * metrics["Anzahl egal"]
    end

    instances = sort(instances, by = rating_function)[1:number]

    questions = map(instances) do instance
        g, path = instance
        tmp = "tmpfile"
        save(SVG(tmp), graph(g))
        img = MoodleFile("$tmp.svg")

        text = "Welche der folgenden Wege sind kürzeste \\(s\\)-\\(t\\)-Wege im abgebildeten Graphen?"
        correct_answer = join(path, " \\rightarrow ")
        answers = [Answer("\\($correct_answer\\)", Correct=1)]

        other_options = collect(setdiff(paths, [path]))[randperm(length(paths) - 1)]
        num_others = min(length(other_options), 3)

        for false_path in [1:num_others]
            false_answer = join(false_path, " \\rightarrow ")
            push!(answers, Answer("\\($false_answer\\)", Correct=0))
        end

        Question(MultipleChoice,
            Name = "Find Shortest Path",
            Text = MoodleText(
                join([text, EmbedFile(img, width="18cm")], "<br />\n"),
                MoodleQuiz.HTML, [img]
            ),
            Answers = answers
        )
    end

    return questions
end

function generateOnestepDijkstraExcercises(G::Graph; number::Int=30, minsteps=2, maxleft=3, max_iterations=1000)
    depths = collect(minsteps:(length(G.V) - maxleft))

    G.positions = spring_positions(G, springlength=0)
    G.directed = true
    sp_labelling!(G)

    questions = []

    iterations = 0
    while (length(questions) < number) && (iterations < max_iterations)
        iterations += 1

        unique_shortestpaths!(G)
        dist, rating, visited = rating_dijkstra(G, depth=rand(depths))

        next_node, next_uniq = argmin(setdiff(G.V, visited), by=dist, return_uniq=true)

        if !next_uniq
            continue
        end

        num_changed = 0
        num_left = 0 

        new_dist = deepcopy(dist)

        for (i, v) in G.E
            if i == next_node
                if dist[v] <= dist[i] + G.c[i, v]
                    num_left += 1
                elseif dist[v] > dist[i] + G.c[i, v]
                    num_changed += 1
                    new_dist[v] = dist[i] + G.c[i, v]
                end
            end
        end

        G.labels = ["$l : $(dist[v] == Inf ? "\\infty" : dist[v])" for (l, v) in zip(G.labels, G.V)]
        save(SVG("tmpfile"), graph(G, marked_nodes=visited))
        dijkstra_img = MoodleFile("tmpfile.svg")

        sp_labelling!(G)

        vector_answer = VectorEmbeddedAnswer(
            [new_dist[v] for v in G.V],
            labels=G.labels
        )

        push!(questions, Question(EmbeddedAnswers,
            Name="Dijkstra Einzelschritt",
            Text=MoodleText("""
                Führen Sie im unten abgebildeten Graphen eine Iteration des Dijkstra-Algorithmus aus. <br />
                <center>$(EmbedFile(dijkstra_img, width="12cm", height="8cm"))</center><br />
                $vector_answer
                """,

                MoodleQuiz.HTML, [dijkstra_img])
            )
        )
    end

    return questions   
end

export multiple_st_paths!
function multiple_st_paths!(G; s=1, t=-1, num_ambiguities=2)
    if t == -1
        t = G.V[end]
    end
    
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
            end
        end
    end
    # Setze Label gemäß KWA-Kantenkosten
    H = deepcopy(G)
    H.E = collect(T)
    label = dijkstra(H, root=s)
    
    # We have one path already
    ambiguity = 1
    # Put the other edges back in
    for (i, j) in random_order(G.E)
        if (i, j) ∉ T
            if ambiguity < num_ambiguities && reachable(G, j, t) && label[j] ≥ label[i]
                # TODO: Für Dijkstra positive Kanten wahren?
                ambiguity += 1
                G.c[i, j] = label[j] - label[i]
                println(" -> ", (i, j), ": ", G.c[i,j])
            else
                G.c[i, j] = max(0, label[j] - label[i] + 1)
                println((i, j), ": ", G.c[i,j])
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
    s = 1
    t = G.V[end]

    q = [[s]]
    costs = [0]

    paths = []

    count = 0
    while !isempty(q)
        if isempty(q)
            break
        end
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