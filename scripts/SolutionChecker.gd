extends Node

class_name SolutionChecker

# Class representing a solution
class Solution:
	# Whether the solution is right
	var is_correct: bool
	# An array of [x, y] coordinates of the cells which are wrong
	# This is not (necessarily) the cells which are in the wrong rotation
	# It's the cells whose rules are broken because of a cell in the wrong rotation 
	var wrong_cells: Array
	
	# Simple constructor
	func _init():
		is_correct = true
		wrong_cells = []
	
	# Add a wrong cell and set is_correct to false
	func add_wrong(x: int, y: int):
		is_correct = false
		wrong_cells.append([x, y])

# ------------RULES------------
# Pointers: The edges being pointed to must have a bar on at least one side

static func check_solution(puzzle: Array, solution: Array) -> Solution:
	# A Solution to add results into
	var result = Solution.new()

	# Get which edges have a bar on at least one side
	var edges := get_filled_edges(puzzle, solution)

	# Loop over all cells and check whether the rules are followed
	for x in range(len(solution)):
		for y in range(len(solution[0])):
			var icon = puzzle[PuzzleClasses.CELLS][x][y]
			if icon == null: continue
			if icon[0] in PuzzleClasses.POINTERS:
				if not check_pointer(x, y, icon[0], edges): result.add_wrong(x, y)

	return result

class FilledEdges:
	# The horizontal edges
	# bool[x][y + 1]
	var horizontal: Array
	# The vertical edges
	# bool[x + 1][y]
	var vertical: Array
	func _init(x: int, y: int):
		# Initiase horizontal with the right dimensions
		horizontal = []
		for i in range(x):
			horizontal.append([])
			for _j in range(y + 1):
				horizontal[i].append(false)
		# Initiase vertical with the right dimensions
		vertical = []
		for i in range(x + 1):
			vertical.append([])
			for _j in range(y):
				vertical[i].append(false)

# Takes a puzzle solution and returns which edges have a bar on at least one side of them
static func get_filled_edges(puzzle: Array, solution: Array) -> FilledEdges:
	# A FilledEdges object to add data to
	var edges := FilledEdges.new(len(solution), len(solution[0]))
	# For each cell, set the edge the right side of it to true
	for x in range(len(solution)):
		for y in range(len(solution[0])):
			if puzzle[PuzzleClasses.CELLS][x][y] != null and puzzle[PuzzleClasses.CELLS][x][y][0] == PuzzleClasses.NONE: continue
			match solution[x][y]:
				0: # Up
					edges.horizontal[x][y] = true
				1: # Right
					edges.vertical[x + 1][y] = true
				2: # Down
					edges.horizontal[x][y + 1] = true
				3: # Left
					edges.vertical[x][y] = true

	return edges

# Checks only pointer icons
static func check_pointer(x: int, y: int, icon: int, edges: FilledEdges) -> bool:
	# Get which directions the icon points
	var directions = PuzzleClasses.POINT_DIRECTIONS[icon]

	# Up
	if directions[0] and not edges.horizontal[x][y]: return false
	# Right
	if directions[1] and not edges.vertical[x + 1][y]: return false
	# Down
	if directions[2] and not edges.horizontal[x][y + 1]: return false
	# Left
	if directions[3] and not edges.vertical[x][y]: return false
	
	# If all pass, return true
	return true
