#!/usr/bin/julia
using ADMStructures
using Greedy
using MoodleQuiz
using Tqdm

# PARAMETER
NUM_EXCERCISES  =   1     # Anzahl der Aufgaben, die generiert werden
RANGE_ON_TREE   = 1:8     # Zufallsbereich für Elemente der Basis
OFFSET_RANGE    = 1:1     # Zufallsbereich, für die Verteuerung von Elementen außerhalb der Basis

# Der Graph auf dem die Aufgaben generiert werden
G = build_mesh_graph(2, 3)
G = Graph([1, 2, 3, 4, 5, 6, 7],
    [(1, 2), (1, 3), (1, 4), (2, 4), (2, 6), (3, 4), (3, 5),
    (3, 7), (4, 6), (4, 7), (5, 7), (6, 7)])

greedy_labelling!(G)
spring_positions!(G, width=5, height=5)

set_string = x -> "{$(join(x, ", "))}" # Wandelt ein Array in das Format {1, 2, 3, ...} um

random_spantrees = []
while(length(random_spantrees) < 5)
    T = random_spantree(G)
    if !(T in random_spantrees)
        push!(random_spantrees, T)
    end
end

questions = []

for i in tqdm(1:NUM_EXCERCISES)
    B = uniqueify_spantree!(G)
    
    # Höchstens 100 Versuche
    for i in 1:100 
        # Es soll ein Basiselement geben, das teurer ist als ein
        # Nichtbasiselement, damit die Aufgabe interessant ist
        c = x -> G.c[x[1], x[2]]
        if any(any(c(k) < c(e) for k in setdiff(G.E, B)) for e in B)
            break
        end
        B = uniqueify_spantree!(G)
    end
    
    img_basic = graph_moodle(G)
    img_right = graph_moodle(G, highlight_edges = B)

    answertext = MoodleText(
        EmbedFile(img_right, width="10cm"),
        MoodleQuiz.HTML,
        [img_right]
    )
    answers = [Answer(answertext, Correct=1)]

    for T in random_spantrees
        if Set(T) != Set(B)
            img_false = graph_moodle(G, highlight_edges = T)
            
            answertext = MoodleText(
                EmbedFile(img_false, width="10cm"),
                MoodleQuiz.HTML,
                [img_false]
            )
            push!(answers, Answer(answertext, Correct=0))
        end
    end

    text = MoodleText("""
        <p>Welche der folgenden Spannbäume sind minimale Spannbäume im abgebildeten Graphen?</p>"
        $(EmbedFile(img_basic, width="10cm"))
        """,
        MoodleQuiz.HTML,
        [img_basic]
    )
    
    q = Question(AllOrNothingMultipleChoice,
        Name = "Mimaler Spannbaum",
        Text = text,
        Answers = answers
    )

    push!(questions, q)
end

quiz = Quiz(questions, Category="GreedyGraph")    # Fragen -> Quiz
exportXML(quiz, "spantree.xml")                   # Quiz -> XML
