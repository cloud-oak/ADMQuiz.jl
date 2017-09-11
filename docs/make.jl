ENV["DOCUMENTER_DEBUG"] = true;

push!(LOAD_PATH, joinpath(dirname(dirname(@__FILE__)), "ADMQuiz"))
using Documenter, ADMStructures, ShortestPaths, Greedy, Knapsack, MaxFlow

makedocs(
    format = :html,
    sitename = "ADMQuiz",
    pages = ["Überblick" => "index.md",
             "ADMStructures.jl" => "ADMStructures.md",
             "Greedy.jl" => "Greedy.md",
             "ShortestPaths.jl" => "ShortestPaths.md",
			 "Knapsack.jl" => "Knapsack.md",
             "MaxFlow.jl" => "MaxFlow.md"],
    modules = [ADMStructures, ShortestPaths, Greedy, Knapsack, MaxFlow]
)

deploydocs(
    repo   = "github.com/cloud-oak/ADMQuiz.jl.git",
)
