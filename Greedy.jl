module Greedy
push!(LOAD_PATH, pwd())

using ADMStructures
using MoodleQuiz
using TikzPictures
using MoodleTools

# TODO: maybe move Partition to ADMStructures?
export Partition
type Partition
    """
    Disjoint-Set structure für Kruskal
    See https://en.wikipedia.org/wiki/Disjoint-set_data_structure
    """
    parent::Dict
    _component::Dict
    component::Function
    find::Function
    union::Function

    function Partition(entries::Any)
        self = new()
        self.parent = Dict((v, v) for v in entries)
        self._component = Dict((v, Set(v)) for v in entries)
        self.component = x -> self._component[partition_find(self, x)]
        self.find = x -> partition_find(self, x)
        self.union = (x, y) -> partition_union(self, x, y)
        return self
    end
end

function partition_find(self::Partition, x)
    """
    Finds an Element's class within a partition
    """
    if self.parent[x] != x
        self.parent[x] = partition_find(self, self.parent[x])
    end
    return self.parent[x]
end

function partition_union(self::Partition, x, y)
    """
    Merges two classes in a partition
    """
    root_x = self.find(x)
    root_y = self.find(y)
    if length(self._component[root_x]) >= length(self._component[root_y])
        for v in self._component[root_y]
            self.parent[v] = root_x
        end
        self._component[root_x] = union(self._component[root_x], self._component[root_y])
    else
        for v in self._component[root_x]
            self.parent[v] = root_y
        end
        self._component[root_y] = union(self._component[root_x], self._component[root_y])
    end
end

export kruskal
function kruskal(G; break_on_unique=false, min_depth=Inf)
    """
    Kruskal's algorithm
    """
    E = G.E
    V = G.V
    c = (e -> G.c[e[1], e[2]])

    parts = Partition(G.V)
    F = Set()
    Q = Set(G.E)

    for i in 1:length(G.E)
        e, uniq = argmin(Q, by=c, return_uniq=true)
        delete!(Q, e)
        v, w = e
        if parts.find(v) != parts.find(w)
            if i >= min_depth && break_on_unique && uniq
                return F
            end
            push!(F, e)
            parts.union(v, w)
        end
    end
    if break_on_unique
        return F, e
    else
        return F
    end
end

export random_spantree
function random_spantree(G)
    """
    Generiert einen zufälligen Spannbaum mit Kruskal
    """
    true_costs = G.c
    G.c = rand(1:100, length(G.V), length(G.V))
    T = kruskal(G)
    G.c = true_costs
    return T
end

export uniqueify_spantree!
function uniqueify_spantree!(G; range_on_tree=1:8, offset_range=1:1)
  """
  Modifiziert die Kosten des Graphen sodass `T`
  der eindeutige Minimale Spannbaum ist.
  """
  T = random_spantree(G)
  G.c = zeros(Int64, length(G.V), length(G.V))

  for (v, w) in T
    G.c[v, w] = rand(range_on_tree)
  end
  G.c += transpose(G.c) # Symmetrische Distanzmatrix

  for (v, w) in setdiff(G.E, T)
    G.c[v, w] = max_edge_in_path(G, T, v, w) + rand(offset_range)
    G.c[w, v] = G.c[v, w]
  end

  return T
end

function max_edge_in_path(G::Graph, edge_subset=G.E, s=1, t=-1)
    assert(G.c == transpose(G.c))
    
    if t == -1
        t = G.V[end]
    end
    
    q = [[s]]
    max_edges = [0]

    while !isempty(q)
        path = pop!(q)
        max_edge = pop!(max_edges)
        
        last = path[end]
        
        for (i, j) in edge_subset
            if j == last
                i, j = j, i
            end
            if i == last
                if j == t
                    return max(max_edge, G.c[i, j])
                elseif (j ∉ path) || (s == t == j) # Keine Kreise außer s=t
                    push!(q, path ∪ [j])
                    push!(max_edges, max(max_edge, G.c[i, j]))
                end
            end
        end
    end
    paths
end

export uniqueify_matroid
function uniqueify_matroid(m::Matroid, range_on_basis=1:8, offset_range=1:1)
	"""
	Algorithmus 2.2
	"""
    costs = Dict()

    # Wähle zufällige Basis
    B = rand(bases(m))
    
    for e in B
		# beliebige Kosten auf B
        costs[e] = rand(range_on_basis)
    end
    
    for c in circles(m)
        rest = setdiff(c, B)
        if length(rest) == 1
            # Es gibt eine Kreisrotation von B um c
            e = first(rest)
            costs[e] = maximum(costs[k] for k in intersect(c, B)) + rand(offset_range)
        end
    end
    return costs, B
end

end
