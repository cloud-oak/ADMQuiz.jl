#!/usr/bin/julia
push!(LOAD_PATH, joinpath(dirname(@__FILE__), "ADMQuiz"))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using ADMStructures
using ShortestPaths
using Tqdm
using MoodleQuiz

NUM_EXCERCISES = 30        # Anzahl an Aufgaben, die generiert werden
RANGE_ON_TREE = 1:8        # Zufallsbereich für Kanten auf der KWA
OFFSET_RANGE = 1:1         # Zufallsbereich, wieviel teurer Kanten außerhalb der KWA sind
MODE = TwoPaths            # DijkstraFail => Generiere Graphen, auf denen Dijkstra versagt
                           # TwoPaths     => Generiere Instanzen mit zwei kürzesten s-t-Wegen
                           # None         => Instanzen mit eindeutigen s-v-Wegen für alle v
G = build_mesh_graph(3, 3) # Der Graph

G.directed = true
spring_positions!(G, springlength=0)
sp_labelling!(G)

questions = []
    
for i in tqdm(1:NUM_EXCERCISES)
    q = generateDijkstraQuestion(G, mode=MODE, range_on_tree=RANGE_ON_TREE, offset_range=OFFSET_RANGE, minsteps=2, maxleft=3, max_iterations=20)
end

quiz = Quiz(questions, "DijkstraFull")
exportXML(quiz, "dijkstra_full.xml")
