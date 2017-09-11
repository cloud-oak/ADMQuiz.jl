var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Überblick",
    "title": "Überblick",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#ADMQuiz-1",
    "page": "Überblick",
    "title": "ADMQuiz",
    "category": "section",
    "text": "Das Modul ADMQuiz/ADMStructures implementiert die benötigten Datenstrukturen wie Matroide und Graphen, und allgemeine Operationen darauf."
},

{
    "location": "ADMStructures.html#",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.jl",
    "category": "page",
    "text": ""
},

{
    "location": "ADMStructures.html#ADMStructures-1",
    "page": "ADMStructures.jl",
    "title": "ADMStructures",
    "category": "section",
    "text": "DocTestSetup = quote\n    using ADMStructures\n	m = Matroid(bases=[(1, 2, 3), (2, 3, 4)])\nendHier finden sich allgemeine Strukturen der ADM, wie Matroide und (Di-)Graphen."
},

{
    "location": "ADMStructures.html#ADMStructures.Matroid",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.Matroid",
    "category": "Type",
    "text": "Ein Matroid in abstrakter Repräsentation. Wird initialisiert durch das Basensystem:\n\nVariablen:\n\nE: Grundmenge des Matroids\nI: Unabhängige Mengen des Matroids\n\njulia> m = Matroid(bases=[(1, 2, 3), (2, 3, 4)])\nADMStructures.Matroid(Any[1, 2, 3, 4], Any[Int64[], [1], [2], [3], [4], [1, 2], [1, 3], [2, 3], [2, 4], [3, 4], [1, 2, 3], [2, 3, 4]])\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.is_matroid",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.is_matroid",
    "category": "Function",
    "text": "Prüft, ob m tatsächlich ein Matroid ist.\n\njulia> is_matroid(m)\ntrue\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.matroid_graph",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.matroid_graph",
    "category": "Function",
    "text": "Gibt eine hierarchische Repräsentation des Matroids als Tikz-Picture zurück.\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.rank",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.rank",
    "category": "Function",
    "text": "Gibt den Rang eines Matroids zurück\n\njulia> ADMStructures.rank(m)\n3\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.bases",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.bases",
    "category": "Function",
    "text": "Gibt die Basen eines Matroids zurück\n\njulia> bases(m)\n2-element Array{Array{Int64,1},1}:\n [1, 2, 3]\n [2, 3, 4]\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.circles",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.circles",
    "category": "Function",
    "text": "Gibt die Kreise eines Matroids zurück\n\njulia> circles(m)\n1-element Array{Any,1}:\n [1, 4]\n\n\n\n"
},

{
    "location": "ADMStructures.html#Matroide-1",
    "page": "ADMStructures.jl",
    "title": "Matroide",
    "category": "section",
    "text": "Matroid\nis_matroid\nmatroid_graph\nADMStructures.rank\nbases\ncircles"
},

{
    "location": "ADMStructures.html#ADMStructures.Graph",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.Graph",
    "category": "Type",
    "text": "Enthält Information über einen Graphen, gerichtet oder ungerichtet.\n\nVariablen:\n\nV: Die Knoten des Graphen\nE: Die Kanten des Graphen\npositions: Die Position der einzelnen Grahen – Wird per Federnetzwerk bestimmt, falls nicht angegeben.\nlabels: LaTeX-Labels für die einzelnen Knoten\ndirected: Boolean, der angibt, ob der Graph gerichtet ist\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.graph",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.graph",
    "category": "Function",
    "text": "Nimmt einen Graphen und eine Kostenfunktion entgegen und wandelt den Graphen in ein TikzPicture um.\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.graph_svg",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.graph_svg",
    "category": "Function",
    "text": "Funktionsweise wie graph, gibt SVG-Rohdaten zurück.\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.graph_moodle",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.graph_moodle",
    "category": "Function",
    "text": "Funktionsweise wie graph, gibt ein MoodleFile statt ein TikzPicture zurück.\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.spring_positions",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.spring_positions",
    "category": "Function",
    "text": "Findet das bestmögliche rechteckige Federnetzwerk, indem folgendes fixiert ist:\n\nder erste Knoten auf (0 0)\nder letzte Knoten auf (w 0)\nein Knoten auf (cdot h2)\nein Knoten auf (cdot -h2)\n\nAlle Möglichkeiten für die letzten beiden Knoten werden in Betracht gezogen und die beste Kombination gewählt.\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.spring_positions!",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.spring_positions!",
    "category": "Function",
    "text": "Inplace-Version von spring_positions\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.build_mesh_graph",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.build_mesh_graph",
    "category": "Function",
    "text": "Generiert einen rechteckigen Gittergraphen.\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.build_wheel_graph",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.build_wheel_graph",
    "category": "Function",
    "text": "Generiert einen Radgraphen mit n Speichen.\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.greedy_labelling!",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.greedy_labelling!",
    "category": "Function",
    "text": "Gibt den Knoten des Graphen Label, wie es für Minimale Spannbäume üblich ist. Alle Knoten erhalten ein Label v_i.\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.sp_labelling!",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.sp_labelling!",
    "category": "Function",
    "text": "Gibt den Knoten des Graphen Label, wie es für Kürzeste Wege / Max Flow üblich ist. Der erste Knoten wird mit s gelabelt, der letzte mit t. Alle anderen Knoten erhalten ein Label v_i.\n\n\n\n"
},

{
    "location": "ADMStructures.html#Graphen-1",
    "page": "ADMStructures.jl",
    "title": "Graphen",
    "category": "section",
    "text": "Graph\ngraph\ngraph_svg\ngraph_moodle\nspring_positions\nspring_positions!\nbuild_mesh_graph\nbuild_wheel_graph\ngreedy_labelling!\nsp_labelling!"
},

{
    "location": "ADMStructures.html#ADMStructures.powerset",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.powerset",
    "category": "Function",
    "text": "Gibt die Potenzmenge zurück.\n\njulia> powerset([1, 2, 3])\n8-element Array{Any,1}:\n Int64[]  \n [1]      \n [2]      \n [3]      \n [1, 2]   \n [1, 3]   \n [2, 3]   \n [1, 2, 3]\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.argmin",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.argmin",
    "category": "Function",
    "text": "Gibt den Index eines niedrigsten Wertes zurück. Bestimmt wahlweise auch, ob dieser Index eindeutig ist.\n\njulia> argmin([1, 2, 3], return_uniq=true)\n(1, true)\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.random_order",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.random_order",
    "category": "Function",
    "text": "Permutiert eine Liste zufällig. julia> srand(42); random_order([1, 2, 3, 4]) 4-element Array{Int64,1}:  4  3  1  2\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.repr_html",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.repr_html",
    "category": "Function",
    "text": "HTML-Repräsentation eines ADM-Objekts\n\n\n\n"
},

{
    "location": "ADMStructures.html#ADMStructures.repr_tex",
    "page": "ADMStructures.jl",
    "title": "ADMStructures.repr_tex",
    "category": "Function",
    "text": "LaTeX-Repräsentation eines ADM-Objekts\n\n\n\n"
},

{
    "location": "ADMStructures.html#Allgemeine-Funktionen-1",
    "page": "ADMStructures.jl",
    "title": "Allgemeine Funktionen",
    "category": "section",
    "text": "powerset\nargmin\nrandom_order\nrepr_html\nrepr_tex"
},

{
    "location": "Greedy.html#",
    "page": "Greedy.jl",
    "title": "Greedy.jl",
    "category": "page",
    "text": ""
},

{
    "location": "Greedy.html#Greedy.Partition",
    "page": "Greedy.jl",
    "title": "Greedy.Partition",
    "category": "Type",
    "text": "Disjoint-Set structure für Kruskal\n\n\n\n"
},

{
    "location": "Greedy.html#Greedy.generate_matroid_question",
    "page": "Greedy.jl",
    "title": "Greedy.generate_matroid_question",
    "category": "Function",
    "text": "Generiert eine Frage, in der eine Minimalbasis bestimmt werden soll\n\n\n\n"
},

{
    "location": "Greedy.html#Greedy.generate_spantree_question",
    "page": "Greedy.jl",
    "title": "Greedy.generate_spantree_question",
    "category": "Function",
    "text": "Generiert eine Frage, in der ein minimaler Spannbaum bestimmt werden soll\n\n\n\n"
},

{
    "location": "Greedy.html#Greedy.kruskal-Tuple{Any,Any}",
    "page": "Greedy.jl",
    "title": "Greedy.kruskal",
    "category": "Method",
    "text": "Algorithmus von Kruskal\n\n\n\n"
},

{
    "location": "Greedy.html#Greedy.random_spantree-Tuple{Any}",
    "page": "Greedy.jl",
    "title": "Greedy.random_spantree",
    "category": "Method",
    "text": "Generiert einen zufälligen Spannbaum – Kruskal mit zufälligen Gewichten\n\n\n\n"
},

{
    "location": "Greedy.html#Greedy.uniqueify_matroid",
    "page": "Greedy.jl",
    "title": "Greedy.uniqueify_matroid",
    "category": "Function",
    "text": "Algorithmus 2.2: Generiert eine Kostenfunktion für das Matroid, sodass B die eindeutige Minimalbasis ist\n\n\n\n"
},

{
    "location": "Greedy.html#Greedy.uniqueify_spantree-Tuple{Any}",
    "page": "Greedy.jl",
    "title": "Greedy.uniqueify_spantree",
    "category": "Method",
    "text": "Algorithmus 2.2: Generiert eine Kostenfunktion für den Graphen, sodass T der eindeutige Minimale Spannbaum ist.\n\n\n\n"
},

{
    "location": "Greedy.html#Greedy.max_edge_in_path",
    "page": "Greedy.jl",
    "title": "Greedy.max_edge_in_path",
    "category": "Function",
    "text": "Hilfsfunktion für random_spantree, im Prinzip eine DFS. Findet das teuerste Gewicht auf dem (vorausgesetzt eindeutigen) s-t-Weg.\n\n\n\n"
},

{
    "location": "Greedy.html#Greedy-1",
    "page": "Greedy.jl",
    "title": "Greedy",
    "category": "section",
    "text": "DocTestSetup = quote\n    using Greedy\nendModules = [Greedy]"
},

{
    "location": "ShortestPaths.html#",
    "page": "ShortestPaths.jl",
    "title": "ShortestPaths.jl",
    "category": "page",
    "text": ""
},

{
    "location": "ShortestPaths.html#ShortestPaths.all_paths-Tuple{ADMStructures.Graph}",
    "page": "ShortestPaths.jl",
    "title": "ShortestPaths.all_paths",
    "category": "Method",
    "text": "Eine DFS die alle s-t-Wege und ihre Länge zurück gibt\n\n\n\n"
},

{
    "location": "ShortestPaths.html#ShortestPaths.dijkstra-Tuple{ADMStructures.Graph,Any}",
    "page": "ShortestPaths.jl",
    "title": "ShortestPaths.dijkstra",
    "category": "Method",
    "text": "Der Algorithmus von Dijkstra\n\n\n\n"
},

{
    "location": "ShortestPaths.html#ShortestPaths.generateDijkstraQuestion-Tuple{ADMStructures.Graph}",
    "page": "ShortestPaths.jl",
    "title": "ShortestPaths.generateDijkstraQuestion",
    "category": "Method",
    "text": "Generiert eine Frage, in der kürzeste Wege bestimmt werden sollen\n\n\n\n"
},

{
    "location": "ShortestPaths.html#ShortestPaths.generateOnestepDijkstraQuestion-Tuple{ADMStructures.Graph}",
    "page": "ShortestPaths.jl",
    "title": "ShortestPaths.generateOnestepDijkstraQuestion",
    "category": "Method",
    "text": "Generiert eine Frage, die einen Einzelschritt des Dijkstra-Algorithmus abfragt\n\n\n\n"
},

{
    "location": "ShortestPaths.html#ShortestPaths.rating_dijkstra-Tuple{ADMStructures.Graph,Any}",
    "page": "ShortestPaths.jl",
    "title": "ShortestPaths.rating_dijkstra",
    "category": "Method",
    "text": "Der Algorithmus von Dijkstra, erweitert um Funktionen zur Bewertung einer Instanz\n\n\n\n"
},

{
    "location": "ShortestPaths.html#ShortestPaths.reachable",
    "page": "ShortestPaths.jl",
    "title": "ShortestPaths.reachable",
    "category": "Function",
    "text": "Überprüft, ob t von s aus erreichbar ist\n\n\n\n"
},

{
    "location": "ShortestPaths.html#ShortestPaths.two_shortestpaths-Tuple{Any}",
    "page": "ShortestPaths.jl",
    "title": "ShortestPaths.two_shortestpaths",
    "category": "Method",
    "text": "Implementierung von Algorithmus 3.3 aus der Arbeit, erweitert um eine gezielte Uneindeutigkeit\n\n\n\n"
},

{
    "location": "ShortestPaths.html#ShortestPaths.unique_shortestpaths-Tuple{Any}",
    "page": "ShortestPaths.jl",
    "title": "ShortestPaths.unique_shortestpaths",
    "category": "Method",
    "text": "Implementierung von Algorithmus 3.3 aus der Arbeit\n\n\n\n"
},

{
    "location": "ShortestPaths.html#ShortestPaths.bellman_ford-Tuple{ADMStructures.Graph,Any}",
    "page": "ShortestPaths.jl",
    "title": "ShortestPaths.bellman_ford",
    "category": "Method",
    "text": "Der Bellman-Ford-Algorithmus\n\n\n\n"
},

{
    "location": "ShortestPaths.html#ShortestPaths-1",
    "page": "ShortestPaths.jl",
    "title": "ShortestPaths",
    "category": "section",
    "text": "DocTestSetup = quote\n    using ShortestPaths \nendModules = [ShortestPaths]"
},

{
    "location": "Knapsack.html#",
    "page": "Knapsack.jl",
    "title": "Knapsack.jl",
    "category": "page",
    "text": ""
},

{
    "location": "Knapsack.html#Knapsack.alpha-NTuple{5,Any}",
    "page": "Knapsack.jl",
    "title": "Knapsack.alpha",
    "category": "Method",
    "text": "Die alpha-Funktion des Knapsack-Algorithmus. Memoisiert, um dynamische Optimierung zu implementieren. Gibt nicht nur den Nutzen, sondern auch die bisher verwendeten Objekte und den in der Arbeit beschriebenen gamma-Wert zurück.\n\n\n\n"
},

{
    "location": "Knapsack.html#Knapsack.generate_knapsack_question-Tuple{}",
    "page": "Knapsack.jl",
    "title": "Knapsack.generate_knapsack_question",
    "category": "Method",
    "text": "Generiert eine Frage, in der ein optimaler Knapsack bestimmt werden soll\n\n\n\n"
},

{
    "location": "Knapsack.html#Knapsack.set_string",
    "page": "Knapsack.jl",
    "title": "Knapsack.set_string",
    "category": "Function",
    "text": "Wandelt ein Array in das Format {1, 2, 3, ...} um\n\njulia> set_string([1, 2, 3, 4])\n\"{1, 2, 3, 4}\"\n\n\n\n"
},

{
    "location": "Knapsack.html#Knapsack.unzip-Tuple{Any}",
    "page": "Knapsack.jl",
    "title": "Knapsack.unzip",
    "category": "Method",
    "text": "Entzippt eine Liste von Tupeln. Umkehrfunktion von zip. Implementierung angepasst von diesem Github Issue.\n\n\n\n"
},

{
    "location": "Knapsack.html#Knapsack-1",
    "page": "Knapsack.jl",
    "title": "Knapsack",
    "category": "section",
    "text": "DocTestSetup = quote\n    using Knapsack \nendModules = [Knapsack]"
},

{
    "location": "MaxFlow.html#",
    "page": "MaxFlow.jl",
    "title": "MaxFlow.jl",
    "category": "page",
    "text": ""
},

{
    "location": "MaxFlow.html#MaxFlow.generate_maxflow_question-Tuple{ADMStructures.Graph}",
    "page": "MaxFlow.jl",
    "title": "MaxFlow.generate_maxflow_question",
    "category": "Method",
    "text": "Generiert eine Frage, in der ein Max Flow bestimmt werden soll\n\n\n\n"
},

{
    "location": "MaxFlow.html#MaxFlow.has_circle",
    "page": "MaxFlow.jl",
    "title": "MaxFlow.has_circle",
    "category": "Function",
    "text": "Überprüft, ob ein gegebener Graph einen Kreis hat. In gerichteten Graphen prüft er den Graphen auf gerichtete Kreise, analog für ungerichtete Graphen.\n\n\n\n"
},

{
    "location": "MaxFlow.html#MaxFlow.uniqueify_network-Tuple{ADMStructures.Graph}",
    "page": "MaxFlow.jl",
    "title": "MaxFlow.uniqueify_network",
    "category": "Method",
    "text": "Implementierung von Algorithmus 5.2 aus der Arbeit\n\n\n\n"
},

{
    "location": "MaxFlow.html#MaxFlow-1",
    "page": "MaxFlow.jl",
    "title": "MaxFlow",
    "category": "section",
    "text": "DocTestSetup = quote\n    using MaxFlow \nendModules = [MaxFlow]"
},

]}
