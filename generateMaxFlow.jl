#!/usr/bin/julia
push!(LOAD_PATH, joinpath(dirname(@__FILE__), "ADMQuiz"))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using ADMStructures
using MaxFlow
using Tqdm
using MoodleQuiz

NUM_EXCERCISES = 10        # Anzahl an Aufgaben, die generiert werden
FLOW_VALUE = 5             # Flusswert
RANDOM_RANGE = 1:5         # Zufallsbereich

proto = Graph([1, 2, 3, 4, 5, 6, 7],
    [(1, 2), (1, 3), (1, 4), (2, 5), (3, 5), (3, 6), (4, 6), (5, 7), (6, 7)]
)


sp_labelling!(proto)
proto.directed = false

questions = []

for i in tqdm(1:NUM_EXCERCISES)
    question = generate_maxflow_question(proto, flow_value=FLOW_VALUE, rand_range=RANDOM_RANGE)

    push!(questions, question)
end

quiz = Quiz(questions, "MaxFlow")
exportXML(quiz, "maxflow.xml")
