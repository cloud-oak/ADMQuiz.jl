#!/usr/bin/julia
push!(LOAD_PATH, joinpath(dirname(@__FILE__), "ADMQuiz"))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using ADMStructures
using MoodleTools
using ShortestPaths
using Tqdm
using MoodleQuiz

NUM_EXCERCISES = 30        # Anzahl an Aufgaben, die generiert werden
RANGE_ON_TREE = 1:8        # Zufallsbereich für Kanten auf der KWA
OFFSET_RANGE = 1:1         # Zufallsbereich, wieviel teurer Kanten außerhalb der KWA sind
G = build_mesh_graph(3, 3) # Der Graph

G.directed = true
spring_positions!(G, springlength=0)
sp_labelling!(G)

questions = []

for i in tqdm(1:NUM_EXCERCISES)
    question = generateOnestepDijkstraQuestion(G::Graph; minsteps=2, maxleft=3, max_iterations=100, range_on_tree=RANGE_ON_TREE, offset_range=OFFSET_RANGE)

    push!(questions, question)
end

quiz = Quiz(questions, "DijkstraOneStep")
exportXML(quiz, "dijkstra_onestep.xml")
