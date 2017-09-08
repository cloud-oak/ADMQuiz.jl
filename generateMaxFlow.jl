#!/usr/bin/julia
push!(LOAD_PATH, joinpath(dirname(@__FILE__), "ADMQuiz"))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using ADMStructures
using MoodleTools
using Tqdm
using MoodleQuiz

proto = Graph([1, 2, 3, 4, 5, 6, 7],
    [(1, 2), (1, 3), (1, 4), (2, 4), (2, 6), (3, 4), (3, 5),
        (3, 7), (4, 6), (4, 7), (5, 7), (6, 7)])

sp_labelling!(proto)
proto.directed = false


