module Greedy
push!(LOAD_PATH, dirname(@__FILE__))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using ADMStructures
using MoodleQuiz

# TODO: maybe move Partition to ADMStructures?
export Partition
"""
Disjoint-Set structure für Kruskal
See https://en.wikipedia.org/wiki/Disjoint-set_data_structure
"""
type Partition
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
"""
Algorithmus von Kruskal
"""
function kruskal(G, c; break_on_unique=false, min_depth=Inf)
    E = G.E
    V = G.V
    cost = (e -> c[e[1], e[2]])

    parts = Partition(G.V)
    F = Set()
    Q = Set(G.E)

    for i in 1:length(G.E)
        e, uniq = argmin(Q, by=cost, return_uniq=true)
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
    Generiert einen zufälligen Spannbaum -- Kruskal mit zufälligen Gewichten
    """
    c = rand(1:100, length(G.V), length(G.V))
    T = kruskal(G, c)
    return T
end

export uniqueify_spantree
function uniqueify_spantree(G; range_on_tree=1:8, offset_range=1:1)
  """
  Modifiziert die Kosten des Graphen sodass `T`
  der eindeutige Minimale Spannbaum ist.
  """
  T = random_spantree(G)
  c = zeros(Int64, length(G.V), length(G.V))

  for (v, w) in T
    c[v, w] = rand(range_on_tree)
  end
  c += transpose(c) # Symmetrische Distanzmatrix

  for (v, w) in setdiff(G.E, T)
    c[v, w] = max_edge_in_path(G, c, v, w, edges=T) + rand(offset_range)
    c[w, v] = c[v, w]
  end

  return T, c
end

STD_GRAPH = Graph([1, 2, 3, 4, 5, 6, 7],
    [(1, 2), (1, 3), (1, 4), (2, 4), (2, 6), (3, 4), (3, 5),
    (3, 7), (4, 6), (4, 7), (5, 7), (6, 7)])
greedy_labelling!(STD_GRAPH)
spring_positions!(STD_GRAPH, width=5, height=5)

export generate_spantree_question
function generate_spantree_question(G::Graph=STD_GRAPH; range_on_tree=1:8, offset_range=1:1)
    T, c = uniqueify_spantree(G)

    # Höchstens 100 Versuche
    for i in 1:100
        # Es soll ein Basiselement geben, das teurer ist als ein
        # Nichtbasiselement, damit die Aufgabe interessant ist
        cost = x -> c[x[1], x[2]]
		if maximum(cost(e) for e in T) > minimum(cost(e) for e in setdiff(G.E, T))
            break
        end

        T, c = uniqueify_spantree(G)
    end
 
    img_basic = graph_moodle(G, c)

	# Richtige Antwort bauen
    img_right = graph_moodle(G, c, highlight_edges = T)

    answertext = MoodleText(
        EmbedFile(img_right, width="10cm"),
        MoodleQuiz.HTML,
        [img_right]
    )
    answers = [Answer(answertext, Correct=1)]

	# Falsche Antworten hinzufügen
	while(length(answers) < 4)
		R = random_spantree(G)
        if Set(T) != Set(R)
            img_false = graph_moodle(G, c, highlight_edges = R)
            
            answertext = MoodleText(
                EmbedFile(img_false, width="10cm"),
                MoodleQuiz.HTML,
                [img_false]
            )
            push!(answers, Answer(answertext, Correct=0))
        end
    end

    text = MoodleText("""
        <!-- Set overflow-x to `scroll` to be at least somewhat mobile-friendly -->
        <div style="overflow-x: auto;">
        <p>Welche der folgenden Spannbäume sind minimale Spannbäume im abgebildeten Graphen?</p>
        $(EmbedFile(img_basic, width="10cm"))
        </div>
        """,
        MoodleQuiz.HTML,
        [img_basic]
    )
    
    q = Question(AllOrNothingMultipleChoice,
        Name = "Mimaler Spannbaum",
        Text = text,
        Answers = answers
    )

	return q
end

function max_edge_in_path(G::Graph, c, s=1, t=-1; edges=G.E)
	"""
	Hilfsfunktion für `random_spantree`, im Prinzip eine DFS.
	Findet das teuerste Gewicht auf dem (vorausgesetzt eindeutigen) s-t-Weg.
	"""
	# Wir benötigen eine symmetrische Distanzmatrix
    assert(c == transpose(c))
    
    if t == -1
        t = G.V[end]
    end
    
    q = [[s]]
    max_edges = [0]

    while !isempty(q)
        path = pop!(q)
        max_edge = pop!(max_edges)
        
        last = path[end]
        
        for (i, j) in edges
            if j == last
                i, j = j, i
            end
            if i == last
                if j == t
					# Wir setzen Eindeutigkeit des s-t-Wegs voraus,
					# können also an dieser Stelle abbrechen
                    return max(max_edge, c[i, j])
                elseif (j ∉ path) || (s == t == j) # Keine Kreise außer s=t
                    push!(q, path ∪ [j])
                    push!(max_edges, max(max_edge, c[i, j]))
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
	for tries in 1:10
		costs = Dict()

		# Wähle zufällige Basis
		B = rand(bases(m))
		
		for e in B
			# beliebige Kosten auf B
			costs[e] = rand(range_on_basis)
		end
		
		for e in setdiff(m.E, B)
			for K in circles(m)
				outer = setdiff(K, B) # Teil des Kreises außerhalb der Basis 
				if (length(outer) == 1) && (first(outer) == e) # <=> K = K_B(e)
					c_lower = maximum(costs[k] for k in K ∩ B)
					costs[e] = c_lower + rand(offset_range)
				end
			end
		end

		# Sicherstellen, dass Lösung eindeutig
		_, unique = argmin(bases(m), by = (b -> sum(costs[e] for e in b)), return_uniq=true)
		if unique
			return costs, B
		end
	end
	# Hartnäckiger Fall... Wir ziehen uns zurück auf Satz 2.11, injektive Kostenfunktion
	costs = Dict(zip(m.E, randperm(length(m.E))))
	B = argmin(bases(m), by = (b -> sum(costs[e] for e in b)))

	return costs, B
end

export generate_matroid_question
function generate_matroid_question(M::Matroid=STD_MATROID; range_on_basis=1:8, offset_range=1:1)
	"""
	Generiert Matroid-Frage im MoodleQuiz-Format
	"""
	set_string = x -> "{$(join(x, ", "))}" # Wandelt ein Array in das Format {1, 2, 3, ...} um

    c, B = uniqueify_matroid(M)

    # Höchstens 100 Versuche
    for i in 1:100 
        # Es soll ein Basiselement geben, das teurer ist als ein
        # Nichtbasiselement, damit die Aufgabe interessant ist
		if maximum(c[e] for e in B) > minimum(c[e] for e in setdiff(M.E, B))
            break
        end
        c, B = uniqueify_matroid(M)
    end

    solution = set_string(B) # Die richtige Lösung als String
    # Stack - ProblemResponseTree bauen
    input = StackInput(AlgebraicInput, "ans1", solution, SyntaxHint="{1, 2, 3, ...}", SyntaxAttribute=1)
    tree = PRTree()
    node1 = PRTNode(tree, input, solution)

    text = """
    <!-- Set overflow-x to `scroll` to be at least somewhat mobile-friendly -->
    <div style="overflow-x: auto;">
    <p>Finden Sie für das Matroid \$\\mathcal{M}\$ eine minimale Basis unter der Kostenfunktion \$c\$.</p>
    $(repr_html(M, c))
    $(EmbedInput(input))
    </div>
    """

	return Question(Stack, Name="Greedy-Algorithmus",
					Text=text, Inputs=[input], ProblemResponseTree=tree)
end

end # module
