module MaxFlow
push!(LOAD_PATH, dirname(@__FILE__))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using ADMStructures
using ShortestPaths
using MoodleQuiz
using MoodleTools

export has_circle
"""
Überprüft, ob ein gegebener Graph einen Kreis hat.
In gerichteten Graphen prüft er den Graphen auf gerichtete Kreise,
analog für ungerichtete Graphen.
"""
function has_circle(G::Graph, exclude_whirls=true)
    for v in G.V
        paths = all_paths(G, s=v, t=v)
        if exclude_whirls
            if any(l > 2 for (p, l) in paths)
                return true
            end
        elseif length(paths) > 0
            return true
        end
    end
    return false
end

export uniqueify_network
"""
Implementierung von Algorithmus 5.2 aus der Arbeit
"""
function uniqueify_network(proto::Graph; flow_value=5, rand_range=1:5, s=first(proto.V), t=last(proto.V))
    # Schritt 1: Generiere einen kreisfreien Fluss, Grundvoraussetzung für ein kreisfreies N_f
    circ = true

    flow = zeros(length(proto.E))
    fmin = zeros(length(proto.E))
    fmax = zeros(length(proto.E))

    Nf = deepcopy(proto)
    Nf.directed = true
    Nf.E = []

    e2i = Dict(e => i for (i, e) in enumerate(proto.E)) # Kante -> Index
    i2e = Dict(i => e for (i, e) in enumerate(proto.E)) # Index -> Kante

    while circ
        single_flows = rand(all_paths(proto), flow_value) # Fluss als Summe von n Wegen
        flow = zeros(length(proto.E)) # Flussvektor
        fmin = zeros(length(proto.E)) # untere Grenze für `flow` = -c((w, v))
        fmax = zeros(length(proto.E)) # obere  Grenze für `flow` =  c((v, w))

        for (f, l) in single_flows
            for (v, w) in zip(f[1:end-1], f[2:end])
                if (v, w) in proto.E
                    flow[e2i[(v, w)]] += 1 # Fluss für v->w positiv
                elseif (w, v) in proto.E
                    flow[e2i[(w, v)]] -= 1 # Fluss für v->w negativ
                end
            end
        end
        
        Nf.E = []

        for (i, val) in enumerate(flow)
            v, w = i2e[i]
            if val > 0
                push!(Nf.E, (w, v))
                fmin[i] = -flow[i]
                if(v != s && w != t)
                    fmin[i] -= rand(rand_range)
                end
            elseif val < 0
                push!(Nf.E, (v, w))
                if (v != t && w != s)
                    fmax[i] += rand(rand_range)
                end
            end
        end

        if !has_circle(Nf)
            circ = false
        end
    end
    
    # Schritt 2: Füge Kanten zu N_f hinzu, die
    #   1. Keinen s-t-Weg in N_f schließen
    #   2. Keinen Kreis in N_f schließen
    for e in random_order(proto.E)
        i, j = e
        if !((i, j) in Nf.E) && (i != t) && (j != s) # s hat Ingrad 0, t hat Ausgrad 0
            push!(Nf.E, (i, j)) # Füge e hinzu
            if reachable(Nf, s, t) || has_circle(Nf)
                pop!(Nf.E) # Lösche es wieder, wenn es Kreis oder s-t-Weg schließt
            else
                assert(fmax[e2i[e]] == 0) # nichts überschreiben
                fmax[e2i[e]] = rand(rand_range)
            end
        end
        if !((j, i) in Nf.E) && (i != s) && (j != t) # s hat Ingrad 0, t hat Ausgrad 0
            push!(Nf.E, (j, i)) # Füge -e hinzu
            if reachable(Nf, s, t) || has_circle(Nf)
                pop!(Nf.E) # Lösche es wieder, wenn es Kreis oder s-t-Weg schließt
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
    c = zeros(Int64, length(N.V), length(N.V))

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

export generate_maxflow_question
"""
Generiert eine Frage, in der ein Max Flow bestimmt werden soll
"""
function generate_maxflow_question(G::Graph; flow_value=5, rand_range=1:5)
    N, c, f = uniqueify_network(G, flow_value=flow_value, rand_range=rand_range)

    img = graph_moodle(N, c, edge_label_attr="flowlabel")
    
    answer_vectors = []
    ENTRIES_PER_ROW = 12
    idx = 0

    solution = collect(f)
    sort!(solution, by=(x -> 1000 * sum(x[1]) + 10 * minimum(x[1]) + x[1][1]))
    labels = ["($(N.labels[e[1]]), $(N.labels[e[2]]))" for (e, _) in solution]
    values = [Int(i) for (_, i) in solution]

    vector_answer = VectorEmbeddedAnswer(values, labels=labels)

    return Question(EmbeddedAnswers,
        Name="Max Flow",
        Text=MoodleText("""
            <!-- Set overflow-x to `scroll` to be at least somewhat mobile-friendly -->
            <div style="overflow-x: auto;">
            Finden sie mithilfe des Ford-Fulkerson-Algorithmus einen maximalen Fluss im abgebildeten Netzwerk.
            <br />
            $(EmbedFile(img, width="16cm"))<br />
            $vector_answer
            </div>
            """,
            MoodleQuiz.HTML, [img])
        )
end

end
