import sys, os

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

# this list will hold all neighboring nodes of each node
neighbors = [[None] for node in range(DIAMETER*DIAMETER)]

for i in range(DIAMETER):
	for j in range(DIAMETER):
		# find neighbors of this node
