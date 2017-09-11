# ADMStructures
```@meta
DocTestSetup = quote
    using ADMStructures
	m = Matroid(bases=[(1, 2, 3), (2, 3, 4)])
end
```
Hier finden sich allgemeine Strukturen der ADM, wie Matroide und (Di-)Graphen.

## Matroide
```@docs
Matroid
is_matroid
matroid_graph
ADMStructures.rank
bases
circles
```

## Graphen
```@docs
Graph
graph
graph_svg
graph_moodle
spring_positions
spring_positions!
build_mesh_graph
build_wheel_graph
greedy_labelling!
sp_labelling!
```

## Allgemeine Funktionen
```@docs
powerset
argmin
random_order
repr_html
repr_tex
```
