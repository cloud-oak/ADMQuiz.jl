module MaxFlow
push!(LOAD_PATH, dirname(@__FILE__))

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
function uniqueify_network(G::Graph, flow_value=5, rand_range=1:5)

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
        sp_labelling!(G)
        dijkstra_img = graph_moodle(G, c, marked_nodes=visited)

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

end
