module MaxFlow
push!(LOAD_PATH, dirname(@__FILE__))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))


using ADMStructures
using ShortestPaths
using MoodleQuiz

export has_circle
"""
Checks whether a given Graph has a circle.
In digraphs it will look for directed circles whereas in undirected
graphs it will look for undirected circles.
"""
function has_circle(G::Graph, exclude_whirls=true)
    for v in G.V
        paths = all_paths(G, s=v, t=v)
        if exclude_whirls
            if any(length(p) > 3 for p in paths)
                return true
            end
        elseif length(paths) > 0
            return true
        end
    end
    return false
end

export uniqueify_network
function uniqueify_network(proto::Graph, flow_value=5, rand_range=1:5)
    # Schritt 1: Generiere einen kreisfreien Fluss, Grundvoraussetzung für ein kreisfreies N_f
    circ = true

    flow = zeros(length(proto.E))
    fmin = zeros(length(proto.E))
    fmax = zeros(length(proto.E))

    while circ
        fmin = zeros(length(proto.E)) # untere Grenze für `flow` = -c((w, v))
        fmax = zeros(length(proto.E)) #  obere Grenze für `flow` =  c((v, w))
        
        e2i = Dict(e => i for (i, e) in enumerate(proto.E)) # Kante -> Index
        i2e = Dict(i => e for (i, e) in enumerate(proto.E)) # Index -> Kante

        s = proto.V[1] 
        t = proto.V[end]
        single_flows = rand(all_paths(proto), flow_val) # Fluss als Summe von n Wegen

        for f in single_flows
            for (v, w) in zip(f[1:end-1], f[2:end])
                if (v, w) in proto.E
                    flow[e2i[(v, w)]] += 1 # Fluss für v->w positiv
                    fmin[e2i[(v, w)]] -= 1 # Augmentationsnetzwerk bekommt rückwärts +1 Kapazität
                elseif (w, v) in proto.E
                    flow[e2i[(w, v)]] -= 1 # Fluss für v->w negativ
                    fmax[e2i[(w, v)]] += 1 # Augmentationsnetzwerk bekommt vorwärts +1 Kapazität
                end
            end
        end
        
        G = deepcopy(proto)
        G.directed = true
        G.E = []

        for (i, val) in enumerate(flow)
            v, w = i2e[i]
            if fmax[i] > 0
                push!(G.E, (v, w))
                fmax[i] += rand(rand_range)
            end
            if fmin[i] < 0
                push!(G.E, (w, v))
                fmin[i] -= rand(rand_range)
            end
        end

        if !has_circle(G)
            circ = false
        end
    end
    
    # Schritt 2: Füge Kanten zu N_f hinzu, die
    #   1. Keinen s-t-Weg in N_f schließen
    #   2. Keinen Kreis in N_f schließen
    for e in random_order(proto.E)
        i, j = e
        if !((i, j) in G.E)
            push!(G.E, (i, j)) # Füge e hinzu
            if reachable(G, s, t) || has_circle(G)
                pop!(G.E) # Lösche es wieder, wenn es Kreis oder s-t-Weg schließt
            else
                assert(fmax[e2i[e]] == 0) # nichts überschreiben
                fmax[e2i[e]] = rand(rand_range)
            end
        end
        if !((j, i) in G.E)
            push!(G.E, (j, i)) # Füge -e hinzu
            if reachable(G, s, t) || has_circle(G)
                pop!(G.E) # Lösche es wieder, wenn es Kreis oder s-t-Weg schließt
            else
                assert(fmin[e2i[e]] == 0) # nichts überschreiben
                fmin[e2i[e]] = -rand(rand_range)
            end
        end
    end

    # Deaugmentierung:
    fmin += flow
    fmax += flow

    N = deepcopy(proto)
    N.directed = true
    N.E = []
    c = zeros(Int64, length(G.V), length(G.V))
    for (i, e) in enumerate(proto.E)
        v, w = e
        if fmax[i] > 0
            push!(N.E, (v, w))
            c[v, w] = fmax[i]
        end
        if fmin[i] < 0
            push!(N.E, (w, v))
            c[w, v] = -fmin[i]
        end
    end

    f = Dict{Tuple, Int64}()

    for (v, w) in N.E
        if (v, w) in keys(e2i)
            val = flow[e2i[(v, w)]]
            f[(v, w)] = max(0, val)
        elseif (w, v) in keys(e2i)
            val = -flow[e2i[(w, v)]]
            f[(v, w)] = max(0, val)
        end
    end

    return N, c, f
end

export generateMaxFlowQuestion
function generateMaxFlowQuestion(G::Graph; flow_value=5, rand_range=1:5)
    N, c, f = uniqueify_network(G, flow_value=rand_range, rand_range=rand_range)

    img = graph_moodle(G, c, edge_label_attr="flowlabel")
    
    answer_vectors = []
    ENTRIES_PER_ROW = 12
    idx = 0

    solution = collect(f)
    sort!(solution, by=(x -> 1000 * sum(x[1]) + 10 * minimum(x[1]) + x[1][1]))
    labels = ["\$$(N.labels[e[1]]) \\to $(N.labels[e[2]])\$" for e, _ in solution]
    values = [Int(i) for _, i in solution]
    while idx * ENTRIES_PER_ROW <= length(solution)
        answer_vectors.
    end
        
    # TODO
    vector_answer = VectorEmbeddedAnswer(
        [new_dist[v] for v in G.V],
        labels=G.labels
    )

    return Question(EmbeddedAnswers,
        Name="Max Flow",
        Text=MoodleText("""
            Finden sie einen maximalen Fluss im abgebildeten Netzwerk.
            <br />
            $(EmbedFile(img, width="16cm"))<br />
            $vector_answer
            """,
            MoodleQuiz.HTML, [dijkstra_img])
        )
end

end
