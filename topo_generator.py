import sys, os
import math, copy

def helper():
	print "Usage: python "+sys.argv[0]+" [Diameter(integer)] [Range(float)] [topology_file name(string)]\n\n"

def print_grid(grid):
	if grid == [] or grid is None:
		return

	for i in range(len(grid)):
		print "( ",
		for j in range(len(grid[0])):
			if j != len(grid[0]) - 1:
				print str(grid[i][j])+"\t", 
			else:
				if grid[i][j] < 10:
					print str(grid[i][j]) + ' ',
				else:
					print str(grid[i][j]), 

		print(")\n")



DIAMETER = 2
RANGE = 1.0
D_LIMIT = 100
R_LIMIT = 20
# Verify amount of arguments.
if len(sys.argv) != 4:
	print "\nInvalid amount of arguments. Try again."
	helper()
	sys.exit(1)


# # Verify DIAMETER and RANGE inputs. 
try:
	DIAMETER = int(sys.argv[1])
	RANGE = float(sys.argv[2])
	FILENAME = sys.argv[3]

	# Diameter, Lets limit at 50
	if DIAMETER > D_LIMIT:
		print "Diamater value too high"
		sys.exit(1)
	elif RANGE >= R_LIMIT:
		print "Range value too high"
		sys.exit(1)

except ValueError:
	print "\nInvalid value for arguments. Try again." 
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



def calculate_distance(node1, node2):
	# node1, node2 are tuples (i, j) with coordinates in the grid
	if node1 == None or node2 == None:
		return -1
	distance = math.sqrt((node1[0] - node2[0])**2 + (node1[1] - node2[1])**2)
	return round(distance, 2)




# use dfs to find all neighbors for each node, according to the specified range.
def dfs(grid, ground_node, current_node_connections, current_node, visited, srange=RANGE, length=DIAMETER):
	
	(i, j) = current_node

	if i >= 0 and i < length and j >= 0 and  j < length and not visited[i][j] : #and ground_node != current_node
		
		visited[i][j] = True

		current_range = calculate_distance(ground_node, current_node)
		# base statement
		if current_range > srange:
			return 

		if ground_node != current_node:
			current_node_connections.append((grid[ground_node[0]][ground_node[1]], grid[current_node[0]][current_node[1]]))


		# Recurse for all directions
		#top-left
		top_left_node = (current_node[0] - 1, current_node[1] - 1)
		dfs(grid=grid, ground_node=ground_node, current_node_connections=current_node_connections, current_node=top_left_node, visited=visited, length=DIAMETER)

		#top
		top_node = (current_node[0] - 1, current_node[1])
		dfs(grid=grid, ground_node=ground_node, current_node_connections=current_node_connections, current_node=top_node, visited=visited, length=DIAMETER)

		#top-right
		top_right_node = (current_node[0] - 1, current_node[1] + 1)
		dfs(grid=grid, ground_node=ground_node, current_node_connections=current_node_connections, current_node=top_right_node, visited=visited, length=DIAMETER)

		#right
		right_node = (current_node[0], current_node[1] + 1)
		dfs(grid=grid, ground_node=ground_node, current_node_connections=current_node_connections, current_node=right_node, visited=visited, length=DIAMETER)

		#down-right
		down_right_node = (current_node[0] + 1, current_node[1] + 1)
		dfs(grid=grid, ground_node=ground_node, current_node_connections=current_node_connections, current_node=down_right_node, visited=visited, length=DIAMETER)

		#down
		down_node = (current_node[0] + 1, current_node[1])
		dfs(grid=grid, ground_node=ground_node, current_node_connections=current_node_connections, current_node=down_node, visited=visited, length=DIAMETER)

		#down-left
		down_left_node = (current_node[0] + 1, current_node[1] - 1)
		dfs(grid=grid, ground_node=ground_node, current_node_connections=current_node_connections, current_node=down_left_node, visited=visited, length=DIAMETER)

		#left
		left_node = (current_node[0], current_node[1] - 1)
		dfs(grid=grid, ground_node=ground_node, current_node_connections=current_node_connections, current_node=left_node, visited=visited, length=DIAMETER)

		return 
	return 


def find_connections_rec(grid, srange=RANGE, diameter=DIAMETER):

	# Guard statements
	if grid is None or grid == []:
		return

	connections = list()

	for i in range(diameter):
		for j in range(diameter):

			current_node = (i, j)

			visited = [[False for k in range(diameter)] for m in range(diameter)]

			current_node_connections = list()

			dfs(grid=grid, ground_node=current_node, current_node_connections=current_node_connections, current_node=current_node, visited=visited, srange=srange, length=diameter)

			connections.append(current_node_connections)

	
	return connections


connections = find_connections_rec(nodes_grid, RANGE, DIAMETER)
print(connections)



# Must "sort" the connections
def sort_connections(connections):

	c_connections = copy.deepcopy(connections)
	
	for cons in c_connections:
		for n_index, node in enumerate(cons):
			ground_index = node[0]
			index = node[1]
			if index < ground_index:
				continue

			for i, n in enumerate(c_connections[index]):

				if n[1] == ground_index:
					matched_node = c_connections[index].pop(i)
					c_connections[ground_index].insert(n_index + 1, matched_node)
					break
				
	return c_connections
			

sorted_connections = sort_connections(connections=connections)

print(sorted_connections)

def write_file(file_name, connections):
    print "\n\nCreating a topology file..." 
    with open(file_name, "w") as file:
        for conn in connections:
            for node in conn:
                if conn is not None or conn != []:
                    file.write(str(node[0])+" "+str(node[1])+" -50.0\n")
            file.write("\n")

        print "\nWriting complete..."

    	


write_file(FILENAME, sorted_connections)


# visited = [[False for k in DIAMETER] for l in DIAMETER]

# def find_connections_v2(grid, diameter, srange):
#     conn = list()
#     for i in range(diameter):
#         for j in range(diameter):
            
#             # current node is (i, j)
#             current_node = (i, j)
#             for m in diameter:
#                 if m - i > 0 and m - i > srange and not visited[i][m]:
#                     conn.append((grid[i][j], grid[i][m]))
#                     conn.append((grid[i][m], grid[i][j]))

#                 if m - j > 0 and m - j > srange:
#                     conn.append((grid[i][j], grid[m][j]))
#                 	conn.append((grid[i][m]), grid[i][j])

#                 if 
                
                    


			
            


print("\n\n")
