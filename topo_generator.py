import sys, os
import math

def helper():
	print("Usage: python "+sys.argv[0]+" [Diameter(integer)] [Range(float)]\n\n")

def print_grid(grid):
	if grid == [] or grid is None:
		return

	for i in range(len(grid)):
		print "(",
		for j in range(len(grid[0])):
			if j != len(grid[0]) - 1:
				print str(grid[i][j])+"\t",
			else:
				if grid[i][j] < 10:
					print str(grid[i][j]) + ' ',
				else:
					print str(grid[i][j]),

		print ")\n"



DIAMETER = 0
RANGE = 0.0
D_LIMIT = 100
R_LIMIT = 20
# Verify amount of arguments.
if len(sys.argv) != 3:
	print("\nInvalid amount of arguments. Try again.")
	helper()
	sys.exit(1)


# Verify DIAMETER and RANGE inputs. 
try:
	DIAMETER = int(sys.argv[1])
	RANGE = float(sys.argv[2])

	# Diameter, Lets limit at 50
	if DIAMETER >= D_LIMIT:
		print("Diamater value too high")
		sys.exit(1)
	elif RANGE >= R_LIMIT:
	 	print("Range value too high")
	 	sys.exit(1)

except ValueError:
	print("\nInvalid value for arguments. Try again.")
	helper()
	sys.exit(2)



# D*D nodes
# Dj, j := {0,...,D^2 - 1}
# j:  row j / D and column j % D 

# Init 
nodes_grid = [[None for y in range(DIAMETER)] for x in range(DIAMETER)]
node_id = 0

for i in range(DIAMETER):
	for j in range(DIAMETER):
		nodes_grid[i][j] = node_id
		node_id += 1

print_grid(nodes_grid)



# Need to calculate neighbors, Pehraps use a search algorithm?
# Duplicates would arise.

# vertical/horizontal neighboring distance is 1
n_distance = 1

def calculate_distance(node1, node2):
	# node1, node2 are tuples (i, j) with coordinates in the grid
	if node1 == None or node2 == None
		return -1
	distance = math.sqrt((node1[0] - node2[0])**2 + (node[1] - node[2])**2)
	return round(distance, 2)




# direction vectors
dRow = [-1, 0, 1, 0]
dCol = [-1, 0, 1, 0]



# use dfs to find all neighbors for each node, according to the specified range.
def dfs(ground_node, current_node_connections, current_node, visited, current_range=0.0):
	
	(i, j) = current_node

	if i >= 0 and i < len(grid) and j >= 0 and  j < len(grid[0]) and not visited[i][j] and ground_node != current_node:
		
		visited[i][j] = True

		# base statement
		if current_range >= RANGE:
			return True

		current_range = calculate_distance(ground_node, current_node)

		# Recurse for all directions
		for h in range(8):
			adjx = 


		#top-left
		top_left_node = (current_node[0] - 1, current_node[1] - 1)
		dfs(current_node_connections, top_left_node, visited, current_range)

		#top
		top_node = (current_node[0] - 1, current_node[1])
		dfs(current_node_connections, top_node, visited, current_range)

		#top-right
		top_right_node = (current_node[0] - 1, current_node[1] + 1)
		dfs(current_node_connections, top_right_node, visited, current_range)

		#right
		right_node = (current_node[0], current_node[1] + 1)
		dfs(current_node_connections, right_node, visited, current_range)

		#down-right
		down_right_node = (current_node[0] + 1, current_node[1] + 1)
		dfs(current_node_connections, down_right_node, visited, current_range)

		#down
		down_node = (current_node[0] + 1, current_node[1])
		dfs(current_node_connections, down_node, visited, current_range)

		#down-left
		down_left_node = (current_node[0] + 1, current_node[1] - 1)
		dfs(current_node_connections, down_left_node, visited, current_range)

		#left
		left_node = (current_node[0], current_node[1] - 1)
		dfs(current_node_connections, left_node, visited, current_range)

		return True
	return False


def find_connections(grid, distance, range):

	# Guard statements
	if grid is None or grid == []:
		return
	if distance <= 0:
		return

	connections = list()

	for i in range(len(grid)):
		for j in range(len(grid[0])):

			current_node = (i, j)

			visited = [[False for k in range(len(table[0]))] for m in range(len(table))]

			current_node_connections = list()

			dfs(ground_node=current_node, current_node_connections=current_node_connections, current_node=current_node, visited=visited, current_range=0)

			connections.append(current_node_connections)


# this list will hold all neighboring nodes of each node
neighbors = [[None] for node in range(DIAMETER*DIAMETER)]

for i in range(DIAMETER):
	for j in range(DIAMETER):
		# find neighbors of this node
