using ADMStructures
using ShortestPaths
using TikzPictures
using MoodleQuiz

function generatePathsMC(G=build_mesh_graph(4, 4); number=30, right_answers=2, false_answers=2)
    questions = []
    tmp = "tmpfile"
    text = "Welche der folgenden Wege sind kürzeste \\(s\\)-\\(t\\)-Wege im abgebildeten Graphen?"
    
    G.positions = spring_positions(G, springlength=0)
    G.directed = true
    sp_labelling!(G)
    
    for i in 1:number
        @label retry_generation
        multiple_st_paths!(G, num_ambiguities=right_answers)

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

        save(SVG(tmp), graph(G))
        img = MoodleFile("$tmp.svg")

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