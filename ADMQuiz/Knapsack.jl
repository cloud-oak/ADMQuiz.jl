module Knapsack
push!(LOAD_PATH, dirname(@__FILE__))
push!(LOAD_PATH, dirname(dirname(@__FILE__)))

using Memoize
using MoodleQuiz

"""
Entzippt eine Liste von Tupeln. Umkehrfunktion von `zip`.
Implementierung angepasst von [diesem Github Issue](https://github.com/JuliaLang/julia/issues/13942).
"""
function unzip(zipped)
	n = length(zipped)
	m = length(first(zipped))
	vectors = [Vector(n) for _ in 1:m]
	for (i, tuple) in enumerate(zipped)
		for (j, el) in enumerate(tuple)
			vectors[j][i] = el
		end
	end
	return vectors
end

export alpha
"""
Die ``\\alpha``-Funktion des Knapsack-Algorithmus. Memoisiert, um dynamische Optimierung zu implementieren.
Gibt nicht nur den Nutzen, sondern auch die bisher verwendeten Objekte und den in der Arbeit beschriebenen ``\\gamma``-Wert zurück.
"""
@memoize function alpha(j, w, c, profits, weights)
	if j <= 0
		if w == 0
			return    0, true, []
		else
			return -Inf, true, []
		end
	end
	if w >= weights[j]
		α1, γ1, k1 = alpha(j - 1, w, c, profits, weights)
		α2, γ2, k2 = alpha(j - 1, w - weights[j], c, profits, weights)
		α2 += profits[j]
		if α1 > α2
			return α1, γ1, k1
		elseif α2 > α1
			return α2, γ2, vcat(k2, [j])
		else
			return α1, false, k1
		end
	else
		return alpha(j - 1, w, c, profits, weights)
	end
end

export set_string
"""
Wandelt ein Array in das Format `{1, 2, 3, ...}` um

```jldoctest
julia> set_string([1, 2, 3, 4])
"{1, 2, 3, 4}"
```
"""
set_string = x -> "{$(join(x, ", "))}"

export generate_knapsack_question
"""
Generiert eine Frage, in der ein optimaler Knapsack bestimmt werden soll
"""
function generate_knapsack_question(;m=5, c=10, weight_range=1:10, profit_range=1:10, greedy_check=true)
	ambiguous = true
	knapsack = w = p = []
	while ambiguous
		# Zufällige Gewichte und Nutzen
		w = rand(weight_range, m)
		p = rand(profit_range, m)

		α, γ, knapsacks = unzip(alpha(m, weight, c, p, w) for weight in 0:c)	

		αₘₐₓ = maximum(α)
		indices = [i for (i, a) in enumerate(α) if a == αₘₐₓ]

		if length(indices) == 1
			i, = indices
			if γ[i]
				ambiguous = false
				optimal_profit = α[i]
				knapsack = knapsacks[i]
			else
				ambiguous = true
				continue
			end
		end
		if greedy_check
			greedy_weight = 0
			greedy_profit = 0
			# Greedy
			for (weight, profit) in sort(collect(zip(w, p)), by=e -> -e[2])
				if greedy_weight + weight <= c
					greedy_weight += weight
					greedy_profit += profit
				end
			end
			if greedy_profit == optimal_profit
				ambiguous = true
				continue
			end
		end
	end

	solution = set_string(knapsack) # Die richtige Lösung als String
    
    input = StackInput(AlgebraicInput, "ans1", solution, SyntaxHint="{1, 2, 3, ...}", SyntaxAttribute=1)
    tree = PRTree()
    node1 = PRTNode(tree, input, solution)

    len = length(w)
    
    text = """
    <!-- Set overflow-x to `scroll` to be at least somewhat mobile-friendly -->
    <div style="overflow-x: auto;">
    <div>Lösen Sie das folgende Knapsack-Problem mit einer Gewichtsoberschranke von \$$(c)\$</div>
        \$\$
        \\begin{array}{l|$(repeat("c", len))}
            &$(join(1:len, "&")) \\\\
            \\hline
            \\text{Gewicht}&$(join(w, "&")) \\\\
            \\text{Nutzen}&$(join(p, "&"))
        \\end{array}
        \$\$
        $(EmbedInput(input))
    </div>
    """
    
    return Question(Stack, Name="Knapsack",
        Text = text,
        Inputs = [input],
        ProblemResponseTree=tree)
end
end
