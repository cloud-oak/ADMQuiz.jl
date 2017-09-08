push!(LOAD_PATH, "../ADMQuiz")
using Documenter, ADMStructures

makedocs(
    format = :html,
    sitename = "ADMQuiz",
    pages = ["ADMQuiz" => "index.md"]
)

deploydocs(
    repo   = "github.com/cloud-oak/ADMQuiz.git",
)
