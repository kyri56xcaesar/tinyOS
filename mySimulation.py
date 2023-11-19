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

for i in range(0,10):
	m=t.getNode(i)
	m.bootAtTime(10*t.ticksPerSecond() + i)



# Handle topology files
# Either as argument file or prefixed.

TOPOLOGY_FILE = "topology.txt" # Default value

# function to print usage of this program. In case of missusage. Exit afterwards.
def helper():
	print("\n\nUsage:\tpython "+sys.argv[0]+" [topoloygy_file.txt]\n\nIf not topology file specified, default: "+TOPOLOGY_FILE)
	print("\n")

# Check for arguments and configure topology file if given.
if len(sys.argv) != 1:
	if len(sys.argv) > 2:
		print("Invalid number of arguments. Try again.")
		helper()
		sys.exit(1)


	split_text = sys.argv[1].split('.')

	if len(split_text) != 2 or split_text[1] != "txt":
		print("Invalid topology file argument. Try again.")
		helper()
		sys.exit(1)


	TOPOLOGY_FILE = sys.argv[1]
	



topo = open(TOPOLOGY_FILE, "r")

if topo is None:
	print "Topology file not opened!!! \n"


	
r=t.radio()
lines = topo.readlines()
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
		for i in range(0,10):
			t.getNode(i).addNoiseTraceReading(val)
noiseF.close()
for i in range(0,10):
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

print "Node 0 connected with node 1" , r.connected(0,1) , r.connected(1,0)
print "Node 0 connected with node 2" , r.connected(0,2) , r.connected(2,0)
print "Node 1 connected with node 7" , r.connected(1,7) , r.connected(7,1)
print "Node 2 connected with node 3" , r.connected(2,3) , r.connected(3,2)
print "Node 4 connected with node 8" , r.connected(4,8) , r.connected(8,4)


