#!/usr/bin/julia
include("./ADMStructures.jl")
using ADMStructures

using Greedy
using MoodleQuiz
using Tqdm

# PARAMETER
NUM_EXCERCISES  = 100     # Anzahl der Aufgaben, die generiert werden
RANGE_ON_BASIS  = 1:8     # Zufallsbereich für Elemente der Basis
OFFSET_RANGE    = 1:1     # Zufallsbereich, für die Verteuerung von Elementen außerhalb der Basis

# Das Matroid auf dem die Aufgaben generiert werden
M = Matroid(bases=[[1, 3, 4], [1, 3, 5], [1, 4, 5], [2, 3, 4], [2, 3, 5], [2, 4, 5]])
# Sicher stellen, dass `M` auch ein Matroid ist!
result = is_matroid(M)
if result != true
    throw(AssertionError(result))
end

set_string = x -> "{$(join(x, ", "))}" # Wandelt ein Array in das Format {1, 2, 3, ...} um

questions = []

for i in tqdm(1:NUM_EXCERCISES)
    c, B = uniqueify_matroid!(M)

    # Höchstens 100 Versuche
    for i in 1:100 
        # Es soll ein Basiselement geben, das teurer ist als ein
        # Nichtbasiselement, damit die Aufgabe interessant ist
        if any(any(c[k] < c[e] for k in setdiff(M.E, B)) for e in B)
            break
        end
        c, B = uniqueify_matroid!(M)
    end

    solution = set_string(B) # Die richtige Lösung als String
    
    # Stack - ProblemResponseTree bauen
    input = StackInput(AlgebraicInput, "ans1", solution, SyntaxHint="{1, 2, 3, ...}", SyntaxAttribute=1)
    tree = PRTree()
    node1 = PRTNode(tree, input, solution)

    text = """<p>Finden Sie für das Matroid \$\\mathcal{M}\$ eine minimale Basis unter der Kostenfunktion \$c\$.</p>
    $(repr_html(M))
    $(EmbedInput(input))
    """

    push!(questions, Question(Stack, Name="Greedy-Algorithmus", Text=text, Inputs=[input], ProblemResponseTree=tree))
end

quiz = Quiz(questions, Category="GreedyMatroid")  # Fragen -> Quiz
exportXML(quiz, "greedy.xml")                     # Quiz -> XML
