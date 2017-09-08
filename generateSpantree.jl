#!/usr/bin/julia
push!(LOAD_PATH, joinpath(dirname(@__FILE__), "ADMQuiz"))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using ADMStructures
using Greedy
using MoodleQuiz
using Tqdm

# PARAMETER
NUM_EXCERCISES  =  20     # Anzahl der Aufgaben, die generiert werden
RANGE_ON_TREE   = 1:8     # Zufallsbereich für Elemente der Basis
OFFSET_RANGE    = 1:1     # Zufallsbereich, für die Verteuerung von Elementen außerhalb der Basis

# Der Graph auf dem die Aufgaben generiert werden
G = Graph([1, 2, 3, 4, 5, 6, 7],
    [(1, 2), (1, 3), (1, 4), (2, 4), (2, 6), (3, 4), (3, 5),
    (3, 7), (4, 6), (4, 7), (5, 7), (6, 7)])

greedy_labelling!(G)
spring_positions!(G, width=5, height=5)

set_string = x -> "{$(join(x, ", "))}" # Wandelt ein Array in das Format {1, 2, 3, ...} um

questions = []

for i in tqdm(1:NUM_EXCERCISES)
	q = generate_spantree_question(G, range_on_tree=RANGE_ON_TREE, offset_range=OFFSET_RANGE)

    push!(questions, q)
end

quiz = Quiz(questions, Category="GreedyGraph")    # Fragen -> Quiz
exportXML(quiz, "spantree.xml")                   # Quiz -> XML
