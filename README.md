# rts-unit-pathfinding-astar

RTS unit path finding implementation for my [godot RTS game](aa) tutorial series. In the implementation, I implemented [a-star algorithm](aa) in similar fashion to what my original tutorial on pathfinding using astar algoroithm were (that was in python). Here I used godot's built-in a-star implementation to work on my custom graph, and a function to find shortest path from source to destination position.

Additionally, I implemented [path simplification algorithm](aa) to smoothen the path geenrated by A-star algorithm, since the astar path was more stairy/jagged/zigzad as the graph's edges were made that way. The overall result is satisfactory & should be integrated with my RTS unit.
