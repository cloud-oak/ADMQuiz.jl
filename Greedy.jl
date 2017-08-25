module Greedy

using ADMStructures
using MoodleQuiz
using TikzPictures
using MoodleTools

"""
    Labels the vertices so that it is useful for minimal spantrees.
    All vertices are labelled "v_i"
"""
function greedy_labelling!(G::Graph)
    G.labels = ["v_{$i}" for (i, v) in enumerate(G.V)]
end

type Partition{T}
    """
    A Disjoint-Set structure
    See https://en.wikipedia.org/wiki/Disjoint-set_data_structure
    """
    parent::Dict{T, T}
    _component::Dict{T, Set{T}}
    component::Function
    find::Function
    union::Function

    function Partition{T}(entries::Any) where T
        self = new()
        self.parent = Dict{T, T}((v, v) for v in entries)
        self._component = Dict{T, Set{T}}((v, Set(v)) for v in entries)
        self.component = x -> self._component[partition_find(self, x)]
        self.find = x -> partition_find(self, x)
        self.union = (x, y) -> partition_union(self, x, y)
        return self
    end
end

function partition_find{T}(self::Partition{T}, x::T)
    """
    Finds an Element's class within a partition
    """
    if self.parent[x] != x
        self.parent[x] = partition_find(self, self.parent[x])
    end
    return self.parent[x]
end

function partition_union{T}(self::Partition{T}, x::T, y::T)
    """
    Merges two classes in a partition
    """
    root_x = self.find(x)
    root_y = self.find(y)
    if length(self._component[root_x]) >= length(self._component[root_y])
        for v in self._component[root_y]
            self.parent[v] = root_x
        end
        self._component[root_x] = union(self._component[root_x], self._component[root_y])
    else
        for v in self._component[root_x]
            self.parent[v] = root_y
        end
        self._component[root_y] = union(self._component[root_x], self._component[root_y])
    end
end

function kruskal(G; depth=Inf, break_on_unique=true, min_depth=0)
    """
    Kruskal's algorithm
    """
    E = G.E
    V = G.V
    c = (e -> G.c[e[1], e[2]])
    
    if isinf(depth)
        depth = length(E)
    end

    parts = Partition(G.V)
    F = Set()
    Q = Set(G.E)

    for i in 1:length(G.E)
        e, uniq = argmin(G.E, by=c, return_uniq=true)
        v, w = e
        v, w = e
        if parts.parent[v] != parts.parent[w]
            if i >= min_depth && break_on_unique && uniq
                return F
            end
            push!(F, e)
            parts.union(v, w)
        end
    end
    return F
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

end