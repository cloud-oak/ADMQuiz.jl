#!/usr/bin/julia
push!(LOAD_PATH, joinpath(dirname(@__FILE__), "ADMQuiz"))
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
	question = generate_matroid_question(M, range_on_basis=RANGE_ON_BASIS, offset_range=OFFSET_RANGE)

	push!(questions, question)
end

quiz = Quiz(questions, Category="GreedyMatroid")  # Fragen -> Quiz
exportXML(quiz, "greedy.xml")                     # Quiz -> XML

