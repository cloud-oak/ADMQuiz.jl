using ADMStructures
using MoodleTools
using ShortestPaths
using Tqdm
using MoodleQuiz

NUM_EXCERCISES = 1         # Anzahl an Aufgaben, die generiert werden
PATH_RANGE = 1:8           # Zufallsbereich für Kanten auf der KWA
OFFSET_RANGE = 1:1         # Zufallsbereich, wieviel teurer Kanten außerhalb der KWA sind
G = build_mesh_graph(3, 3) # Der Graph

G.directed = true
spring_positions!(G, springlength=0)
sp_labelling!(G)

function generateOnestepDijkstraExcercises(G::Graph; number::Int=NUM_EXCERCISES, minsteps=2, maxleft=3, max_iterations=1000)
    allowed_depths = collect(minsteps:(length(G.V) - maxleft))

    questions = []

    iterations = 0
    while (length(questions) < number) && (iterations < max_iterations)
        iterations += 1

        unique_shortestpaths!(G)
        dist, rating, visited = rating_dijkstra(G, depth=rand(allowed_depths))

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
        dijkstra_img = graph_moodle(G, marked_nodes=visited)

        sp_labelling!(G)

        vector_answer = VectorEmbeddedAnswer(
            [new_dist[v] for v in G.V],
            labels=G.labels
        )

        push!(questions, Question(EmbeddedAnswers,
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
        )
    end

    return questions   
end

function generatePathsMC(G=build_mesh_graph(4, 4); number=30, right_answers=2, false_answers=2, dijkstra_fail=false)
    questions = []
    text = "Welche der folgenden Wege sind kürzeste \\(s\\)-\\(t\\)-Wege im abgebildeten Graphen?"
    
    G.positions = spring_positions(G, springlength=0)
    G.directed = true
    sp_labelling!(G)
    
    for i in tqdm(1:number)
        @label retry_generation
        if (dijkstra_fail)
            unique_shortestpaths!(G, dijkstra_fail=true)
        else
            multiple_st_paths!(G, num_ambiguities=right_answers)
        end

        paths = all_paths(G)
        dist  = minimum(c for (p, c) in paths)
        correct_paths = [p for (p, c) in paths if c == dist]
        false_paths   = [p for (p, c) in paths if c != dist]

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

        if length(answers) < right_answers + false_answers
            @goto retry_generation
        end
        img = graph_moodle(G)

        push!(questions,
            Question(MultipleChoice,
                Name = "Find Shortest Path",
                Text = MoodleText(
                    join([text, EmbedFile(img, width="18cm")], "<br />\n"),
                    MoodleQuiz.HTML, [img]
                ),
                Answers = answers
            )
        )
    end
    return questions
end

questions = generateOnestepDijkstraExcercises(G)
quiz      = Quiz(questions, "ShortestPathsDijkstraFail")
exportXML(quiz, "dijkstra_fail.xml")
