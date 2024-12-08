extends Node3D

const GRID_SIZE = 128
const CELL_SIZE = 1  # Adjust as needed

var astar: AStar3D

func _ready():
	astar = AStar3D.new()
	create_grid()


func create_grid():
	# Calculate the total number of points and reserve space
	var total_points = (2 * GRID_SIZE + 1) * (2 * GRID_SIZE + 1)
	astar.reserve_space(total_points)

	var point_id = 0
	for x in range(-GRID_SIZE, GRID_SIZE + 1):
		for z in range(-GRID_SIZE, GRID_SIZE + 1):
			var position = Vector3(x * CELL_SIZE, 0, z * CELL_SIZE) # Assuming Y is constant/ground level
			astar.add_point(point_id, position)
			point_id += 1

	# Connect the points
	point_id = 0
	for x in range(-GRID_SIZE, GRID_SIZE + 1):
		for z in range(-GRID_SIZE, GRID_SIZE + 1):
			# Connect to neighbors (right and below). No need for other directions due to bidirectional connections.
			if x < GRID_SIZE:
				astar.connect_points(point_id, point_id + 2 * GRID_SIZE + 1) # Right neighbor
			if z < GRID_SIZE:
				astar.connect_points(point_id, point_id + 1) # Bottom neighbor
			point_id += 1



func get_shortest_path(from_position: Vector3, to_position: Vector3) -> Array[Vector3]:
	var from_id = astar.get_closest_point(from_position)
	var to_id = astar.get_closest_point(to_position)

	if from_id == -1 or to_id == -1:
		print_debug("Error: Start or end position is out of bounds.")
		return [] # Or handle the error differently.

	var path_ids = astar.get_id_path(from_id, to_id)

	if path_ids.is_empty():
		print_debug("Error: No path found between points.")
		return [] # Or handle differently, maybe return partial path if needed.

	var path_points: Array[Vector3] = []

	for id in path_ids:
		path_points.append(astar.get_point_position(id))

	return path_points




@onready var agent = $Agent
var current_agent_path = []
var current_agent_path_index = 0

const RAY_LENGTH = 1000


func _physics_process(delta):
	
	# Raycast related code
	var space_state = get_world_3d().direct_space_state
	var cam = $Camera3D
	var mousepos = get_viewport().get_mouse_position()

	var origin = cam.project_ray_origin(mousepos)
	var end = origin + cam.project_ray_normal(mousepos) * RAY_LENGTH
	var query = PhysicsRayQueryParameters3D.create(origin, end)
	query.collide_with_areas = true
	
	
	# pathfinding code
	if Input.is_action_just_pressed("left_mouse_button"):
		var result = space_state.intersect_ray(query) # raycast result
		
		var from_pos = $Agent.position # Vector3(0, 0, 0)  # Example start point
		var to_pos = result.position if result else $Agent.position # Vector3(5, 0, 5)    # Example end point
		var path = get_shortest_path(from_pos, to_pos)
		path = simplify_path(path, 2.0)
		
		if not path.is_empty():
			print("Shortest path:")
			for point in path:
				print(point)
			current_agent_path = path
			current_agent_path_index = 0  # Reset path index
	
	# Move agent along the path
	if current_agent_path.size() > 0 and current_agent_path_index < current_agent_path.size():
		var target_pos = current_agent_path[current_agent_path_index]
		var direction = (target_pos - agent.position).normalized()
		var distance = agent.position.distance_to(target_pos)
		
		# Move the agent toward the target position
		agent.position += direction * min(distance, delta * 32)  # Cap movement to the remaining distance
		
		# Check if agent reached the current target position
		if distance < 0.5:
			current_agent_path_index += 1  # Move to the next point
			print("Reached waypoint:", current_agent_path_index)
	
	# Clear the path when the destination is reached
	if current_agent_path_index >= current_agent_path.size():
		current_agent_path.clear()
		print("Destination reached")















# path simplification algorithm - smoothen/straighten jagged/zigzag path
# Simplifies a path by removing unnecessary points while preserving the general direction.
# Iterative version of the RDP algorithm.
# @param path: Array of Vector3 points (path from A* algorithm)
# @param tolerance: Minimum distance a point must have from the line to be kept
# @return Array of simplified Vector3 points
func simplify_path(path: Array, tolerance: float) -> Array:
	if path.size() < 3:
		return path  # Cannot simplify if less than 3 points
	
	var result = []  # Final simplified path
	var stack = []  # Stack for segments to process
	stack.append(Vector2(0, path.size() - 1))  # Start with the entire path
	
	var markers = PackedInt32Array()  # Marks points to keep (1 = keep, 0 = discard)
	markers.resize(path.size())
	
	# Mark the first and last points as kept
	markers[0] = 1
	markers[path.size() - 1] = 1
	
	while stack.size() > 0:
		var indices = stack.pop_back()  # Get the current segment (start, end)
		var start_index = indices.x
		var end_index = indices.y
		
		var max_distance = 0
		var farthest_index = -1
		
		# Find the point farthest from the line segment
		for i in range(start_index + 1, end_index):
			var distance = point_line_distance(path[i], path[start_index], path[end_index])
			if distance > max_distance:
				max_distance = distance
				farthest_index = i
		
		# If the farthest point exceeds the tolerance, keep it and add new segments
		if max_distance > tolerance:
			markers[farthest_index] = 1
			stack.append(Vector2(start_index, farthest_index))  # Left segment
			stack.append(Vector2(farthest_index, end_index))  # Right segment
	
	# Collect the points marked as kept
	for i in range(path.size()):
		if markers[i] == 1:
			result.append(path[i])
	
	return result


# Calculates the perpendicular distance of a point from a line segment
# @param point: The point to measure distance from
# @param line_start: Start of the line segment
# @param line_end: End of the line segment
# @return The perpendicular distance
func point_line_distance(point: Vector3, line_start: Vector3, line_end: Vector3) -> float:
	var line = line_end - line_start
	var length_squared = line.length_squared()
	
	if length_squared == 0:
		return (point - line_start).length()  # Line is a single point
	
	# Projection of 'point' onto the line
	var t = ((point - line_start).dot(line)) / length_squared
	t = clamp(t, 0.0, 1.0)  # Clamp to line segment bounds
	var projection = line_start + t * line
	return (point - projection).length()
