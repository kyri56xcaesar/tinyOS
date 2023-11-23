#!/usr/bin/python

from TOSSIM import *
import sys ,os
import random

t=Tossim([])
f=sys.stdout #open('./logfile.txt','w')
SIM_END_TIME= 1000 * t.ticksPerSecond()

print "TicksPerSecond : ", t.ticksPerSecond(),"\n"

t.addChannel("Boot",f)
t.addChannel("RoutingMsg",f)
t.addChannel("NotifyParentMsg",f)
t.addChannel("Radio",f)
#t.addChannel("Serial",f)
t.addChannel("SRTreeC",f)
#t.addChannel("PacketQueueC",f)



# Handle topology files
# Either as argument file or prefixed.

TOPOLOGY_FILE = "topology.txt" # Default value
NO_NODES = 10 # default value
nodes_given = False
MAX_NODES = 100

# function to print usage of this program. In case of missusage. Exit afterwards.
def helper():
	print "\n\nUsage:\tpython "+sys.argv[0]+" [topoloygy_file.txt] [number of nodes(int)]{optional}\n\n\t-> If not topology file specified, default: "+TOPOLOGY_FILE+"\n\t-> If no node number specified, default: "+str(NO_NODES)+"\n"
	print "\n"


# Check for arguments and configure topology file if given.
if len(sys.argv) != 1:
	if len(sys.argv) > 3:
		print "Invalid number of arguments. Try again."
		helper()
		sys.exit(1)


	split_text = sys.argv[1].split('.')

	if len(split_text) != 2 or split_text[1] != "txt":
		print "Invalid topology file argument. Try again."
		helper()
		sys.exit(1)


	TOPOLOGY_FILE = sys.argv[1]
	
	if len(sys.argv) == 3:

		try:
			nodes = int(sys.argv[2])
		except:
			print "Invalid node value. Try again."
			helper()
			sys.exit(1)
		if nodes > MAX_NODES:
			print "Invalid node number. Try again."
			helper()
			sys.exit(1)
		NO_NODES = nodes
		nodes_given = True




topo = open(TOPOLOGY_FILE, "r")

if topo is None:
	print "Topology file not opened!!! \n"

# Read lines from up here
lines = topo.readlines()

# calculate no_nodes from topo file
# NO_NODES
if not nodes_given:
	nodes = set()
	for line in lines:
		if line !="\n":
			line_contents = line.split()
			print line_contents
			nodes.add(int(line_contents[0]))
			nodes.add(int(line_contents[1]))

	#print nodes
	#print len(nodes)
	NO_NODES = len(nodes)






sys.exit(1)


# @TODO configure how many nodes we have.
for i in range(0, NO_NODES):
	m=t.getNode(i)
	m.bootAtTime(10*t.ticksPerSecond() + i)


	
r=t.radio()
# read lines
for line in lines:
  s = line.split()
  if (len(s) > 0):
    print " ", s[0], " ", s[1], " ", s[2];
    r.add(int(s[0]), int(s[1]), float(s[2]))

mTosdir = os.getenv("TINYOS_ROOT_DIR")
noiseF=open(mTosdir+"/tos/lib/tossim/noise/meyer-heavy.txt","r")
lines= noiseF.readlines()

for line in  lines:
	str1=line.strip()
	if str1:
		val=int(str1)
		for i in range(0, NO_NODES):
			t.getNode(i).addNoiseTraceReading(val)
noiseF.close()
for i in range(0, NO_NODES):
	t.getNode(i).createNoiseModel()
	

ok=False
#if(t.getNode(0).isOn()==True):
#	ok=True
h=True
while(h):
	try:
		h=t.runNextEvent()
		#print h
	except:
		print sys.exc_info()
#		e.print_stack_trace()

	if (t.time()>= SIM_END_TIME):
		h=False
	if(h<=0):
		ok=False

# print "Node 0 connected with node 1" , r.connected(0,1) , r.connected(1,0)
# print "Node 0 connected with node 2" , r.connected(0,2) , r.connected(2,0)
# print "Node 1 connected with node 7" , r.connected(1,7) , r.connected(7,1)
# print "Node 2 connected with node 3" , r.connected(2,3) , r.connected(3,2)
# print "Node 4 connected with node 8" , r.connected(4,8) , r.connected(8,4)


