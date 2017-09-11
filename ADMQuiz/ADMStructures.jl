module ADMStructures
push!(LOAD_PATH, dirname(@__FILE__))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using TikzPictures
using Combinatorics
using Memoize
using MoodleQuiz

preamble = readstring(joinpath(dirname(@__FILE__), "res", "tikzheader.tex"))

export powerset
"""
Gibt die Potenzmenge zurück.

```jldoctest
julia> powerset([1, 2, 3])
8-element Array{Any,1}:
 Int64[]  
 [1]      
 [2]      
 [3]      
 [1, 2]   
 [1, 3]   
 [2, 3]   
 [1, 2, 3]
```
"""
function powerset(x)
    result = reduce(union, Set(), [combinations(x, n) for n in 0:length(x)])
    return result
end

export random_order
"""
Permutiert eine Liste zufällig.
julia> srand(42); random_order([1, 2, 3, 4])
4-element Array{Int64,1}:
 4
 3
 1
 2
"""
random_order(list) = list[randperm(length(list))]

export argmin
"""
Gibt den Index eines niedrigsten Wertes zurück.
Bestimmt wahlweise auch, ob dieser Index eindeutig ist.

```jldoctest
julia> argmin([1, 2, 3], return_uniq=true)
(1, true)
```
"""
function argmin(list; by=x->x, return_uniq::Bool=false)
	if by isa Dict
		dict = by
		by = x -> dict[x]
	end

	optimal = Inf
	element = NaN
	unique = true

	for x in list
		if by(x) < optimal
			element = x
			optimal = by(x)
			unique = true
		elseif by(x) == optimal
			unique = false
		end
	end
	if return_uniq
		return element, unique
	else
		return element
	end
end

export Matroid
"""
Ein Matroid in abstrakter Repräsentation. Wird initialisiert durch das Basensystem:

Variablen:
* `E`: Grundmenge des Matroids
* `I`: Unabhängige Mengen des Matroids

```jldoctest
julia> m = Matroid(bases=[(1, 2, 3), (2, 3, 4)])
ADMStructures.Matroid(Any[1, 2, 3, 4], Any[Int64[], [1], [2], [3], [4], [1, 2], [1, 3], [2, 3], [2, 4], [3, 4], [1, 2, 3], [2, 3, 4]])
```
"""
type Matroid
	E
	I
end

function setlt(a, b)
	if length(a) == length(b)
		return string(a) <= string(b)
	else
		return length(a) <= length(b)
	end
end

function Matroid(;bases=[])
	E = reduce(union, Set(), bases)
	sort!(E)
	I = reduce(union, Set(), [powerset(b) for b in bases])
	for i in I
		sort!(i)
	end
	sort!(I, lt=setlt)
    m = Matroid(E, I)
    assert(is_matroid(m))
	return m
end

export is_matroid
"""
Prüft, ob `m` tatsächlich ein Matroid ist.

```jldoctest
julia> is_matroid(m)
true
```
""" 
@memoize function is_matroid(m::Matroid)
  # Unabhängigkeits-Bedingung (m1)
  for e in m.I
      for s in powerset(e)
          if !(s in m.I)
              return "Kein US"
          end
      end
  end
  # Matroid-Bedingung (m2)
  for A in m.I
      for B in m.I
          if length(A) > length(B)
              exchange_possible = false
              for e in setdiff(A, B)
                  if sort(union(B, [e])) in m.I
                      exchange_possible = true
                  end
              end
              if !exchange_possible
                  return string("Austausch: ", B, " -> ", A)
              end
          end
      end
  end
  return true
end

export repr_html, repr_tex
"""
HTML-Repräsentation eines ADM-Objekts
"""

repr_html(x::Any) = string(x)
"""
LaTeX-Repräsentation eines ADM-Objekts
"""
repr_tex(x::Any) = string(x)

repr_tex(v::Vector) = length(v) == 0 ? "\\emptyset" : "\\{$(join([repr_tex(x) for x in v], ", "))\\}"

repr_html(m::Matroid, c) = string(
  "<p>",
  "\\( \\mathcal{M} = (E, \\mathcal I) \\),<br />",
  "\\( E = $(repr_tex(m.E)) \\),<br /> \\( \\mathcal I = $(repr_tex(m.I))) \\)",
  "</p><p>",
  "<table style=\"border:1px solid black; border-collapse: collapse; width:initial;\"><tr><td style=\"border:1px solid black\">\\( e \\)</td>",
  join(["<td style=\"border: 1px solid black\">$e</td>" for e in m.E]),
  "</tr><tr><td style=\"border: 1px solid black\">\\( c(e)\\)</td>",
  join(["<td style=\"border: 1px solid black\">$(c[e])</td>" for e in m.E]),
  "</tr></table>",
  "</p>")

export matroid_graph
"""
Gibt eine hierarchische Repräsentation des Matroids als Tikz-Picture zurück.
"""
function matroid_graph(m::Matroid)
	identifier = i -> "node_$(join(i, "_"))"
	label      = i -> length(i) == 0 ? "\\emptyset" : "\\{$(join(i, ","))\\}"
	positions = Dict()

	paths = ""
	lastlayer = []
	for l = 0:rank(m)
		layer = [i for i in m.I if length(i) == l]
		sort!(layer, by=identifier)

		dx = 3
		dy = 2
		x = -0.5 * (length(layer) - 1) * dx

		for i in layer
			positions[identifier(i)] = (x, 2 * l)
			x += dx
		end

		for i in lastlayer, j in layer
			if i ⊆ j
				paths = string(paths, "\\draw[graph edge] ($(identifier(i))) -- ($(identifier(j)));")
			end
		end

		lastlayer = layer
	end

	nodes = join(["\\node[scale=1.6] ($(identifier(i))) at $(positions[identifier(i)]) {\$$(label(i))\$};" for i in m.I], "\n")

	TikzPicture(string(nodes, paths), preamble=preamble)
end

export Graph
"""
Enthält Information über einen Graphen, gerichtet oder ungerichtet.

Variablen:
* `V`: Die Knoten des Graphen
* `E`: Die Kanten des Graphen
* `positions`: Die Position der einzelnen Grahen – Wird per Federnetzwerk bestimmt, falls nicht angegeben.
* `labels`: LaTeX-Labels für die einzelnen Knoten
* `directed`: Boolean, der angibt, ob der Graph gerichtet ist
"""
type Graph
	V::Vector{Any}
	E::Vector{Any}
	positions::AbstractMatrix
	labels::Vector{AbstractString}
	directed::Bool
	function Graph(vertices, edges; positions=false, labels=false, directed=false)
		this = new()
		if vertices == []
			vertices = unique([x for edge in edges for x in edge])
		end
		this.V = vertices
		this.E = edges
		if positions == false
			positions = spring_positions(this)
		end
		this.positions = positions
		if labels == false
			labels = [string(x) for x in vertices]
		end
		this.labels = labels
		this.directed = directed

		return this
	end
end

export graph
"""
Nimmt einen Graphen und eine Kostenfunktion entgegen und wandelt den Graphen in ein `TikzPicture` um.
"""
function graph(G, c=nothing; highlight_edges = [], marked_nodes = [], bend="auto",
        edge_attr = (G.directed ? "graph path" : "graph edge"),
        edge_label_attr = "fill=white, circle, thin, inner sep=2pt"
    )
    has_c = !(c isa Void)

    hl = [Tuple(x) for x in highlight_edges]
    nodes = join(["\\node[V$(i in marked_nodes ? ", marked" : "")] ($i) at $pos {\$$label\$};" for (i, pos, label) in zip(G.V, zip(G.positions[:,1], G.positions[:,2]), G.labels)], "\n")

    eclass = edge_attr
    hlclass = string(eclass, ", red")
    
    edgestrings = []
    for e in G.E
        i, j = e
        currentbend = bend
        if bend == "auto"
            d = norm(G.positions[i,:] - G.positions[j,:])
            bend_dist = 0.15
            currentbend = 90 - acosd((4*bend_dist*d) / (d*d + 4*bend_dist))
        end
        edge = string(
            "\\draw[$((i, j) in hl ? hlclass : eclass)] ($i) to",
            G.directed && ((j, i) in G.E) ? "[bend right=$(currentbend)]" : "",
            has_c ? " node[midway, $(edge_label_attr)] {\$$(c[i, j])\$} ($j);" : "($j);")
        push!(edgestrings, edge)
    end
    edges = join(edgestrings,"\n")
    
    TikzPicture(string(nodes, edges), preamble=preamble, options="scale=2")
end

export graph_moodle
"""
Funktionsweise wie [`graph`](@ref), gibt ein `MoodleFile` statt ein `TikzPicture` zurück.
"""
function graph_moodle(args...; kwargs...)
  TMP = tempname()

  tp = graph(args...; kwargs...)
  save(SVG(TMP), tp)
  mf = MoodleFile("$TMP.svg")
  rm("$TMP.svg")
  return mf
end

export graph_svg
"""
Funktionsweise wie [`graph`](@ref), gibt SVG-Rohdaten zurück.
"""
function graph_svg(args...; kwargs...)
  save(SVG("tmp"), graph(args...; kwargs...))
  svg = ""
  open("tmp.svg") do f
    svg = readstring(f)
  end
  return svg
end

export spring_positions
"""
Findet das bestmögliche rechteckige Federnetzwerk, indem folgendes fixiert ist:
- der erste Knoten auf ``(0, 0)``
- der letzte Knoten auf ``(w, 0)``
- ein Knoten auf ``(\\cdot, h/2)``
- ein Knoten auf ``(\\cdot, -h/2)``
Alle Möglichkeiten für die letzten beiden Knoten werden
in Betracht gezogen und die beste Kombination gewählt.
"""
function spring_positions(G; width=8, height=5, iterations=100, springlength=0, subdivisions=20)
  n = length(G.V)
  p = zeros(n, 2)

  free_nodes = collect(2:n-1)

  optimal_sqdist = Inf
  optimal_positions = copy(p)

  for upper in free_nodes
      for lower in free_nodes
          if upper == lower
              continue
          end
          p[1,:]  = [0, 0]
          p[n,:] = [width, 0]
          for i in free_nodes
              p[i,:] = [width / 2, 0]
          end
          p[upper,:] = [width / 2, height / 2]
          p[lower,:] = [width / 2,-height / 2]

          lockx = [1, n]
          locky = [1, upper, lower, n]

          for _ in 1:iterations
              for (i, j) in G.E 
                  dx = p[i,1] - p[j,1]
                  dy = p[i,2] - p[j,2]
                  dist = sqrt(dx * dx + dy * dy) - springlength

                  # update x values
                  if i in lockx
                      if !(j in lockx)
                          p[j,1] += dx * dist / subdivisions
                      end
                  elseif j in lockx
                      p[i,1] -= dx * dist / subdivisions
                  else 
                      p[j,1] += dx * dist / (2 * subdivisions)
                      p[i,1] -= dx * dist / (2 * subdivisions)
                  end

                  if i in locky
                      if !(j in locky)
                          p[j,2] += dy * dist / subdivisions
                      end
                  elseif j in locky
                      p[i,2] -= dy * dist / subdivisions
                  else 
                      p[j,2] += dy * dist / (2 * subdivisions)
                      p[i,2] -= dy * dist / (2 * subdivisions)
                  end
              end
          end

          sqdist = 0
          for (i, j) in G.E
              d = p[i, :] - p[j, :]
              sqdist += (sqrt(d' * d) - springlength) ^ 2
          end

          if sqdist < optimal_sqdist
              optimal_sqdist = sqdist
              optimal_positions = copy(p)
          end
      end
  end

  return optimal_positions
end

export spring_positions!
"""
Inplace-Version von [`spring_positions`](@ref)
"""
function spring_positions!(G; width=8, height=5, iterations=100, springlength=0)
  G.positions = spring_positions(G, width=width, height=height, iterations=iterations, springlength=springlength)
end

export build_wheel_graph
"""
Generiert einen [Radgraphen](https://en.wikipedia.org/wiki/Wheel_graph) mit `n` Speichen.
"""
function build_wheel_graph(n)
  V = collect(1:n)
  labels = ["v_{$i}" for i in V]

  positions = zeros(n, 2)
  positions = [(2 * cos(ϕ), 2 * sin(ϕ)) for ϕ in linspace(0, 2 * π, n)]
  positions[n] = (0, 0)

  E = [(i, i+1) for i in 1:(n-2)]
  push!(E, (n-1, 1))
  for i in 1:n-1
      push!(E, (i, n))
  end

  c = zeros(Int, n, n)
  for (i, j) in E
      c[i, j] = 1
      c[j, i] = 1
  end

  return Graph(V, E, c=c, positions=positions, labels=labels)
end

export build_mesh_graph
"""
Generiert einen rechteckigen [Gittergraphen](https://de.wikipedia.org/wiki/Gittergraph).
"""
function build_mesh_graph(width, height)
  n = width * height

  V = collect(1:n)
  labels = ["v_{$i}" for i in V]

  positions = zeros(n, 2)
  positions[:, 1] = [(i-1) % width for i in V]
  positions[:, 2] = [floor((i - 1) / width) for i in V]

  E = vcat([(i, i+1) for i in V if i % width != 0],
   [(i, i+width) for i in 1:(n-width)])

  return Graph(V, E, positions=positions, labels=labels)
end

export rank
"""
Gibt den Rang eines Matroids zurück
```jldoctest
julia> ADMStructures.rank(m)
3
```
"""
function rank(m::Matroid)
  return maximum(length(e) for e in m.I)
end

export bases
"""
Gibt die Basen eines Matroids zurück
```jldoctest
julia> bases(m)
2-element Array{Array{Int64,1},1}:
 [1, 2, 3]
 [2, 3, 4]
```
"""
@memoize function bases(m::Matroid)
  r = rank(m)
  return [b for b in m.I if length(b) == r]
end

export circles
"""
Gibt die Kreise eines Matroids zurück
```jldoctest
julia> circles(m)
1-element Array{Any,1}:
 [1, 4]
```
"""
@memoize function circles(m::Matroid)
  circles = []
  for d in setdiff(powerset(m.E), m.I)
      is_circle = true
      for e in d
          if !(setdiff(d, [e]) in m.I)
              is_circle = false 
              break
          end
      end
      if is_circle
          push!(circles, d)
      end
  end
  circles
end

export greedy_labelling!
"""
Gibt den Knoten des Graphen Label, wie es für Minimale Spannbäume üblich ist.
Alle Knoten erhalten ein Label ``v_i``.
"""
function greedy_labelling!(G::Graph)
    G.labels = ["v_{$i}" for (i, v) in enumerate(G.V)]
end

export sp_labelling!
"""
Gibt den Knoten des Graphen Label, wie es für Kürzeste Wege / Max Flow üblich ist.
Der erste Knoten wird mit ``s`` gelabelt, der letzte mit ``t``.
Alle anderen Knoten erhalten ein Label ``v_i``.
"""
function sp_labelling!(G::Graph)
    G.labels = ["v_{$(i-1)}" for (i, v) in enumerate(G.V)]
    G.labels[1] = "s"
    G.labels[end] = "t"
end

end


