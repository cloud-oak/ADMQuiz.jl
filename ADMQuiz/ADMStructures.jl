module ADMStructures
push!(LOAD_PATH, dirname(@__FILE__))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using TikzPictures
using Combinatorics
using Memoize
using MoodleQuiz

preamble = readstring(joinpath(dirname(@__FILE__), "res", "tikzheader.tex"))

export powerset
function powerset(x)
	result = reduce(union, Set(), [combinations(x, n) for n in 0:length(x)])
  return result
end

export random_order
random_order(list) = list[randperm(length(list))]

export argmin
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

function Matroid(;bases=[], costs=[])
	E = reduce(union, Set(), bases)
	sort!(E)
	I = reduce(union, Set(), [powerset(b) for b in bases])
	for i in I
		sort!(i)
	end
	sort!(I, lt=setlt)
	return Matroid(E, I)
end

export is_matroid
@memoize function is_matroid(m::Matroid)
  """
  Prüft, ob `m` tatsächlich ein Matroid ist.
  """ 
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

@memoize function dim(m::Matroid)
	return maximum([length(i) for i in m.I])
end

export repr_html, repr_tex
repr_html(x::Any) = string(x)
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

export matroidGraph
function matroidGraph(m::Matroid)
	identifier = i -> "node_$(join(i, "_"))"
	label      = i -> length(i) == 0 ? "\\emptyset" : "\\{$(join(i, ","))\\}"
	positions = Dict()

	paths = ""
	lastlayer = []
	for l = 0:dim(m)
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
function graph(G, c=nothing; highlight_edges = [], marked_nodes = [], bend="auto")
    has_c = !(c isa Void)

	hl = [Tuple(x) for x in highlight_edges]

	nodes = join(["\\node[V$(i in marked_nodes ? ", marked" : "")] ($i) at $pos {\$$label\$};" for (i, pos, label) in zip(G.V, zip(G.positions[:,1], G.positions[:,2]), G.labels)], "\n")

    eclass = ""
    hlclass = ""
    if G.directed
        eclass = "graph path"
        hlclass = "graph path, red"
    else
        eclass = "graph edge"
        hlclass = "very thick, red"
    end
    
    edgestrings = []
    for e in G.E
        i, j = e
        currentbend = bend
        if bend == "auto"
            d = norm(G.positions[i,:] - G.positions[j,:])
            currentbend = 90 - acosd(4*d / (d*d + 4))
        end
        edge = string(
            "\\draw[$((i, j) in hl ? hlclass : eclass)] ($i) to",
            G.directed && ((j, i) in G.E) ? "[bend right=$(bend)]" : "",
            has_c ? " node[midway, fill=white, circle, thin, inner sep=2pt] {\$$(c[i, j])\$} ($j);" : "($j);")
        push!(edgestrings, edge)
    end
    edges = join(edgestrings,"\n")
    
    TikzPicture(string(nodes, edges), preamble=preamble, options="scale=2")
end

export graph_moodle
function graph_moodle(G, c; highlight_edges = [], marked_nodes = [])
  TMP = tempname()

  tp = graph(G, c, highlight_edges=highlight_edges, marked_nodes=marked_nodes)
  save(SVG(TMP), tp)
  mf = MoodleFile("$TMP.svg")
  rm("$TMP.svg")
  return mf
end

export graph_svg
function graph_svg(G, c)
  save(SVG("tmp"), graph(G, c))
  svg = ""
  open("tmp.svg") do f
    svg = readstring(f)
  end
  return svg
end

export spring_positions
function spring_positions(G; width=8, height=5, iterations=100, springlength=0, subdivisions=20)
  """
  Brute force a rectangular spring layout by fixing:
  - the first node on (0, 0)
  - the last node on (width, 0)
  - any node on (*, height/2)
  - any other node on (*, -height/2)
  All choices for the last two nodes are considered
  and the one where the spring lengths differ the least
  from the given spring length is chosen.
  """
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
function spring_positions!(G; width=8, height=5, iterations=100, springlength=0)
  G.positions = spring_positions(G, width=width, height=height, iterations=iterations, springlength=springlength)
end

export build_wheel_graph
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
function rank(m::Matroid)
  return maximum(length(e) for e in m.I)
end

export bases
@memoize function bases(m::Matroid)
  r = rank(m)
  return [b for b in m.I if length(b) == r]
end

export circles
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
function greedy_labelling!(G::Graph)
    """
    Labels the vertices so that it is useful for minimal spantrees.
    All vertices are labelled "v_i"
    """
    G.labels = ["v_{$i}" for (i, v) in enumerate(G.V)]
end

export sp_labelling!
"""
Labels the vertices so that it is useful for shortest paths.
The first vertex is labelled "s", the last vertex "t".
All other vertices are labelled "v_i"
"""
function sp_labelling!(G::Graph)
    G.labels = ["v_{$(i-1)}" for (i, v) in enumerate(G.V)]
    G.labels[1] = "s"
    G.labels[end] = "t"
end

end


