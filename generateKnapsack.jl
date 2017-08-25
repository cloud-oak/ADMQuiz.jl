#!/usr/bin/julia
using PyCall
using MoodleQuiz

@pyimport knapsack

# PARAMETERS
NUM_EXCERCISES  = 100     # Anzahl der Aufgaben, die generiert werden
NUM_ELEMENTS    = 5       # Anzahl an Elementen in einer Knapsack Instanz
CAPACITY        = 10      # Kapazität des Knapsacks
WEIGHT_RANGE    = (1, 10) # Bereich, in dem sich die Gewichte befinden
PROFIT_RANGE    = (1, 10) # Bereich für die Nutzenswerte
PREVENT_GREEDY  = false   # Ob Greedy-lösbare Instanzen verworfen werden sollen 

# Instanzen generieren
instances = knapsack.generate_knapsack(
    number = NUM_EXCERCISES,
    m = NUM_ELEMENTS,
    c = CAPACITY,
    weight_range = WEIGHT_RANGE,
    profit_range = PROFIT_RANGE,
    greedy_check = PREVENT_GREEDY
)

set_string = x -> "{$(join(x, ", "))}" # Wandelt ein Array in ein das Format {1, 2, 3, ...} um

function instance_to_question(instance)
    solution = set_string(instance["solution"]) # Die richtige Lösung als String
    
    input = StackInput(AlgebraicInput, "ans1", solution, SyntaxHint="{1, 2, 3, ...}", SyntaxAttribute=1)
    tree = PRTree()
    node1 = PRTNode(tree, input, solution)

    len = length(instance["weights"])
    
    text = """<div>Lösen Sie das folgende Knapsack-Problem mit einer Gewichtsoberschranke von \$$(instance["capacity"])\$</div>
        \$\$
        \\begin{array}{l|$(repeat("c", len))}
            &$(join(1:len, "&")) \\\\
            \\hline
            w&$(join(instance["weights"], "&")) \\\\
            p&$(join(instance["profits"], "&"))
        \\end{array}
        \$\$
        $(EmbedInput(input))
        """
    
    return Question(Stack, Name="Knapsack",
        Text = text,
        Inputs = [input],
        ProblemResponseTree=tree)
end

questions = map(instance_to_question, instances) # Instanzen -> Fragen
quiz = Quiz(questions, Category="KnapsackFull")  # Fragen -> Quiz
exportXML(quiz, "knapsack.xml")                  # Quiz -> XML
