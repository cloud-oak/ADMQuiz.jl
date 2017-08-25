module ADMStructures
using TikzPictures
using Combinatorics

preamble = readstring("tikzheader.tex")

function powerset(x)
	result = reduce(union, Set(), [combinations(x, n) for n in 0:length(x)])
  return result
end

export random_order
random_order(list) = list[randperm(length(list))]

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
	c
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
	c = (x -> costs[x])
	return Matroid(E, I, c)
end

function dim(m::Matroid)
	return maximum([length(i) for i in m.I])
end

repr_html(x::Any) = string(x)
repr_tex(x::Any) = string(x)

repr_tex(v::Vector) = length(v) == 0 ? "\\emptyset" : "\\{$(join([repr_tex(x) for x in v], ", "))\\}"

repr_html(m::Matroid) = string(
  "\\( \\mathcal{M} = (E, \\mathcal I) \\),<br />",
  "\\( E = $(repr_tex(m.E)) \\),<br /> \\( \\mathcal I = $(repr_tex(m.I))) \\)<br />",
  "<table style=\"border:1px solid black; border-collapse: collapse; width:initial;\"><tr><td style=\"border:1px solid black\">\\( e \\)</td>",
  join(["<td style=\"border: 1px solid black\">$e</td>" for e in m.E]),
  "</tr><tr><td style=\"border: 1px solid black\">\\( c(e)\\)</td>",
  join(["<td style=\"border: 1px solid black\">$(m.c(e))</td>" for e in m.E]),
  "</tr></table>")

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
	c::AbstractMatrix
	positions::AbstractMatrix
	labels::Vector{AbstractString}
	directed::Bool
	function Graph(vertices, edges; c=false, positions=false, labels=false, directed=false)
		this = new()
		if vertices == []
			vertices = unique([x for edge in edges for x in edge])
		end
		this.V = vertices
		this.E = edges
		if c == false
			c = zeros(Int, length(vertices), length(vertices))
			for (i, j) in edges
				c[i, j] = 1
				if directed == false
					c[j, i] = 1
				end
			end
		end
		this.c = c
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

function graph(G; highlight_edges = [], marked_nodes = [])
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
   edges = join(["\\draw[$((i, j) in hl ? hlclass : eclass)] ($i) -- ($j) node[midway, fill=white, circle, thin, inner sep=2pt] {\$$(G.c[i, j])\$};" for (i, j) in G.E], "\n")
    
   TikzPicture(string(nodes, edges), preamble=preamble, options="scale=2")
end

function graph_svg(G)
  save(SVG("tmp"), graph(G))
  svg = ""
  open("tmp.svg") do f
    svg = readstring(f)
  end
  return svg
end

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

function spring_positions!(G; width=8, height=5, iterations=100, springlength=2)
  G.positions = spring_positions(G, width=width, height=height, iterations=iterations, springlength=springlength)
end

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


function build_mesh_graph(width, height)
  n = width * height

  V = collect(1:n)
  labels = ["v_{$i}" for i in V]

  positions = zeros(n, 2)
  positions[:, 1] = [(i-1) % width for i in V]
  positions[:, 2] = [floor((i - 1) / width) for i in V]

  E = vcat([(i, i+1) for i in V if i % width != 0],
   [(i, i+width) for i in 1:(n-width)])

  c = zeros(Int, n, n)
  for (i, j) in E
      c[i, j] = 1
      c[j, i] = 1
  end

  return Graph(V, E, c=c, positions=positions, labels=labels)
end

function unique_spantree(G)
  T = Set()
  c = Dict()

  p = Partition{Int}(G.V)

  for (i, j) in G.E[randperm(length(G.E))] 
      if p.find(i) == p.find(j)
          c[(i, j)] = maximum( values(c) ) + 1
      else
          p.union(i, j)
          push!(T, (i, j))
          val = rand(1:5)
          c[(i, j)] = val
      end
  end
  return c, T
end

function circles(m::Matroid)
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

function uniqueify_matroid(m::Matroid)
  elements = m.E[randperm(length(m.E))]
  tmp_E = Set()
  B = Set()
  costs = Dict()

  circs = circles(m)

  for e in elements
      joined = union(B, e)

      if !any([(e in c) for c in circs if issubset(c, joined)])
          costs[e] = rand(1:4)
          push!(B, e)
      else
          costs[e] = 1 + maximum( costs[e] for e in B )
      end
      push!(tmp_E, e)
  end
  return (e -> costs[e]), B
end

function uniqueify_matroid!(m::Matroid)
  c, B = uniqueify_matroid
  m.c = c
  return c, B
end

function randomize_weights(G, sample_from=1:10)
  G.c = rand(sample_from, G.c)
end

function greedy_labelling!(G::Graph)
    """
    Labels the vertices so that it is useful for minimal spantrees.
    All vertices are labelled "v_i"
    """
    G.labels = ["v_{$i}" for (i, v) in enumerate(G.V)]
end

end
