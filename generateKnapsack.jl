#!/usr/bin/julia
using ADMQuiz.Knapsack
using MoodleQuiz
using Tqdm

# PARAMETERS
NUM_EXCERCISES  = 100     # Anzahl der Aufgaben, die generiert werden
NUM_ELEMENTS    = 5       # Anzahl an Elementen in einer Knapsack Instanz
CAPACITY        = 10      # Kapazität des Knapsacks
WEIGHT_RANGE    = 1:10    # Bereich, in dem sich die Gewichte befinden
PROFIT_RANGE    = 1:10    # Bereich für die Nutzenswerte
PREVENT_GREEDY  = false   # Ob Greedy-lösbare Instanzen verworfen werden sollen 

questions = []

# Instanzen generieren
for i in tqdm(1:NUM_EXCERCISES)
	push!(questions, generate_knapsack_question(
		m = NUM_ELEMENTS,
		c = CAPACITY,
		weight_range = WEIGHT_RANGE,
		profit_range = PROFIT_RANGE,
		greedy_check = PREVENT_GREEDY
	))
end

quiz = Quiz(questions, Category="KnapsackFull")  # Fragen -> Quiz
exportXML(quiz, "knapsack.xml")                  # Quiz -> XML
