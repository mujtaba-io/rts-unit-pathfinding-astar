# RTS game unit path finding using A-star algorithm

RTS unit path finding implementation for my [godot RTS game](https://gameidea.org/2024/12/13/how-to-make-an-rts-game-in-godot/) tutorial series. In this implementation, I implemented [navigation system](https://gameidea.org/2024/12/13/making-navigation-system-for-path-finding/) using A-star algorithm in similar fashion to what my original tutorial on pathfinding using astar algoroithm were (that was in python). Here I used godot's built-in a-star implementation to work on my custom graph, and a function to find shortest path from source to destination position.

Additionally, I implemented [path simplification algorithm](https://gameidea.org/short-posts/make-paths-smooth-using-path-simplification/) to smoothen the path geenrated by A-star algorithm, since the astar path was more stairy/jagged/zigzad as the graph's edges were made that way. The overall result is satisfactory & should be integrated with my RTS unit.
