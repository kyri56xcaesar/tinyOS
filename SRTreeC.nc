#include "SimpleRoutingTree.h"

module SRTreeC
{
	// Boot and Radio
	uses interface Boot;
	uses interface SplitControl as RadioControl;

	// For random numbers
	uses interface Random;
	
	// Timers
	uses interface Timer<TMilli> as RoutingMsgTimer;
	uses interface Timer<TMilli> as NotifyDataTimer;

	// Routing
	uses interface Packet as RoutingPacket;
	uses interface AMSend as RoutingAMSend;
	uses interface AMPacket as RoutingAMPacket;
	
	uses interface Receive as RoutingReceive;
	
	
	// Data
	uses interface Packet as NotifyPacket;
	uses interface AMSend as NotifyAMSend;
	uses interface AMPacket as NotifyAMPacket;

	uses interface Receive as NotifyReceive;

	
	// Queuing
	uses interface PacketQueue as RoutingSendQueue;
	uses interface PacketQueue as RoutingReceiveQueue;
	
	uses interface PacketQueue as NotifySendQueue;
	uses interface PacketQueue as NotifyReceiveQueue;

}



implementation
{
	// Rounds(Should be 15)
	uint16_t  roundCounter;
	
	// Routingpackets
	message_t radioRoutingSendPkt;
	// Data packets
	message_t radioNotifySendPkt;
	
	
	// Grouping random number and id
	uint8_t RANDOM_NUM = 1;


	// Node info, depth, group and parent 
	uint8_t curdepth;
	uint16_t parentID;
	uint8_t groupID;
	
	// Node data - measurement
	uint8_t data = 0;

	// Tasks
	task void sendRoutingTask();
	task void receiveRoutingTask();
	
	task void sendNotifyTask();
	task void receiveNotifyTask();

	// Must hold an array of children
	Node children[MAX_CHILDREN];





// Arxiki methodos
	event void Boot.booted()
	{
		roundCounter = 0;
		
		// arxikopoiisi radio 
		call RadioControl.start();
		

		if (TOS_NODE_ID == 0)
		{
			curdepth = 0;
			parentID = 0;
			groupID = 1;


			// Debug messages
			dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);

		}
		else
		{
			curdepth = -1;
			parentID = -1;
			groupID = -1;


			// Debug messages
			dbg("Boot", "curdepth = %d  ,  parentID= %d \n", curdepth , parentID);

		}
	}




// Radio	
	event void RadioControl.startDone(error_t err)
	{
		uint8_t i, offset;

		if (err == SUCCESS)
		{
			dbg("Radio" , "Radio initialized successfully!!!\n");

			for (i = 0; i < MAX_CHILDREN; i++)
			{
				children[i].childID = 0;

				children[i].sum = 0;
				children[i].count = 0;
				children[i].groupID = 0;
		
				children[i].sum2 = 0;
				children[i].count2 = 0;
				children[i].groupID2 = 0;

				children[i].sum3 = 0;
				children[i].count3 = 0;
				children[i].groupID3 = 0;

			}

			//offset =  ((call Random.rand16()) % 10) + 1;
			//dbg("SRTreeC", "offset: %d\n", offset);
			
			//**********in receive routingtask
			//call NotifyDataTimer.startPeriodicAt(TIMER_PERIOD_MILLI-BOOT_TIME-(TIMER_FAST_PERIOD*curdepth), TIMER_PERIOD_MILLI);
			

			if (TOS_NODE_ID == 0)
			{
				//call RoutingMsgTimer.startPeriodicAt((-BOOT_TIME), TIMER_PERIOD_MILLI);
				call RoutingMsgTimer.startOneShot(TIMER_ROUTING_DURATION);
			}


		}
		else
		{
			dbg("Radio" , "Radio initialization failed! Retrying...\n");

			call RadioControl.start();
		}
	}

	
	event void RadioControl.stopDone(error_t err)
	{ 
		dbg("Radio", "Radio stopped!\n");

	}






// Routing
	event void RoutingMsgTimer.fired()
	{
		message_t tmp;
		error_t enqueueDone;
		RoutingMsg* r_msg;
		
		
		//dbg("SRTreeC", "RoutingMsgTimer fired! \n");

		// First Round.
		roundCounter += 1;
		
		if (TOS_NODE_ID == 0)
		{
			dbg("SRTreeC", "\n");
			dbg("SRTreeC", "#####################################\n");
			dbg("SRTreeC", "#######   ROUND   %u    ##############\n", roundCounter);
			dbg("SRTreeC", "#####################################\n");
			dbg("SRTreeC", "\n");
			
			//RANDOM_NUM = ((call Random.rand16()) % 3) + 1;
			dbg("SRTreeC", "RANDOM_NUM: %d\n", RANDOM_NUM);
		}

			
			// error case
		if (call RoutingSendQueue.full())
		{
			dbg("SRTreeC", "RoutingSendQueue is Full! \n");

			return;
		}


		r_msg = (RoutingMsg*)(call RoutingPacket.getPayload(&tmp, sizeof(RoutingMsg)));

		// error case
		if (r_msg == NULL)
		{
			dbg("SRTreeC","RoutingMsgTimer.fired(): No valid payload... \n");

			return;
		}

		atomic{
			r_msg->depth = curdepth;
			r_msg->total_groups = RANDOM_NUM;
		}

		enqueueDone = call RoutingSendQueue.enqueue(tmp);

		if (enqueueDone == SUCCESS)
		{

			if (call RoutingSendQueue.size() == 1)
			{
				//("SRTreeC", "SendRoutingTask() posted!!\n");

				post sendRoutingTask();
			}

			//dbg("SRTreeC","RoutingMsg enqueued successfully in SendingQueue!!!\n");

		}
		else
		{
			dbg("SRTreeC","RoutingMsg failed to be enqueued in SendingQueue!!!");

		}	
		
		
	}


// Routing send.
	event void RoutingAMSend.sendDone(message_t * msg , error_t err)
	{
		//dbg("SRTreeC", "\tRouting message was sent: %s \n", (err == SUCCESS) ? "True" : "False");

		if (!(call RoutingSendQueue.empty()))
		{
			post sendRoutingTask();
		}
		

	
	}

// Routing receive.
	event message_t* RoutingReceive.receive(message_t *msg, void *payload, uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;
		uint16_t msg_source;
		
		msg_source = call RoutingAMPacket.source(msg);
		
		//dbg("SRTreeC", "\tRouting message received from %u\n",  msg_source);

		// Save message  (ensure execution)
		atomic{

			memcpy(&tmp, msg, sizeof(message_t));
		}

		// Enqueue message
		enqueueDone = call RoutingReceiveQueue.enqueue(tmp);
		
		if(enqueueDone == SUCCESS)
		{
			// Post receive task
			post receiveRoutingTask();
		}
		else
		{
			// error
			dbg("SRTreeC","RoutingMsg enqueue failed!!!\n");
		
		}
		
		
		
		return msg;
	}

















	event void NotifyDataTimer.fired()
	{
		uint8_t offset;
		message_t tmp;
		error_t enqueueDone;
		void * n_packet;

		if (TOS_NODE_ID == 0)
		{
			roundCounter += 1;

			dbg("SRTreeC", "\n");
			dbg("SRTreeC", "#####################################\n");
			dbg("SRTreeC", "#######   ROUND   %u    ##############\n", roundCounter);
			dbg("SRTreeC", "#####################################\n");
			dbg("SRTreeC", "\n");
			
		}


	
		// Take a measurement, each measurement is a random value between 1..100. Between rounds it should have 20% drift.
		if (data == 0)
		{
			data = (call Random.rand16()) % 100;
		}
		else
		{
			offset = data * 0.2;
				
			if (data + offset <= 100)
			{
				data += offset;
			}
			else
			{
				data -= offset;
			}
		}

		dbg("SRTreeC", "Node = %d, groupID = %d, curdepth = %d taking Measurement: %d\n", TOS_NODE_ID, groupID, curdepth, data);

		if (call NotifySendQueue.full())
		{
			dbg("SRTreeC", "NotifySendQueue full!\n");
			return;
		}

		// Create the message holding the measurement
		call NotifyAMPacket.setDestination(&tmp, parentID);


		if (RANDOM_NUM == 1) 
		{
				
			n_packet = (NotifyMsg*) (call NotifyPacket.getPayload(&tmp, sizeof(NotifyMsg)));
			call NotifyPacket.setPayloadLength(&tmp, sizeof(NotifyMsg));


			// error
			if (n_packet == NULL)
			{
				dbg("SRTreeC", "NotifyDataTimer.fired(): No valid payload.\n");
			}

			((NotifyMsg*)n_packet)->sum = data;
			((NotifyMsg*)n_packet)->count = 1;
			((NotifyMsg*)n_packet)->groupID = groupID;


		}
		else if (RANDOM_NUM == 2)
		{

			n_packet = (NotifyMsg2*) (call NotifyPacket.getPayload(&tmp, sizeof(NotifyMsg2)));
			call NotifyPacket.setPayloadLength(&tmp, sizeof(NotifyMsg2));


			// error
			if (n_packet == NULL)
			{
				dbg("SRTreeC", "NotifyDataTimer.fired(): No valid payload.\n");
			}

			if (groupID == 1)
			{
				((NotifyMsg2*)n_packet)->sum = data;
				((NotifyMsg2*)n_packet)->count = 1;
				((NotifyMsg2*)n_packet)->groupID = 1;

				((NotifyMsg2*)n_packet)->sum2 = 0;
				((NotifyMsg2*)n_packet)->count2 = 0;
				((NotifyMsg2*)n_packet)->groupID2 = 2;
			}
			else
			{
				((NotifyMsg2*)n_packet)->sum = 0;
				((NotifyMsg2*)n_packet)->count = 0;
				((NotifyMsg2*)n_packet)->groupID = 1;

				((NotifyMsg2*)n_packet)->sum2 = data;
				((NotifyMsg2*)n_packet)->count2 = 1;
				((NotifyMsg2*)n_packet)->groupID2 = 2;
			}




		}
		else 
		{
			n_packet = (NotifyMsg3 *) (call NotifyPacket.getPayload(&tmp, sizeof(NotifyMsg3)));
			call NotifyPacket.setPayloadLength(&tmp, sizeof(NotifyMsg3));

			// error
			if (n_packet == NULL)
			{
				dbg("SRTreeC", "NotifyDataTimer.fired(): No valid payload.\n");
			}

			if (groupID == 1)
			{
				
				((NotifyMsg3*)n_packet)->sum = data;
				((NotifyMsg3*)n_packet)->count = 1;
				((NotifyMsg3*)n_packet)->groupID = 1;

				((NotifyMsg3*)n_packet)->sum2 = 0;
				((NotifyMsg3*)n_packet)->count2 = 0;
				((NotifyMsg3*)n_packet)->groupID2 = 2;

				((NotifyMsg3*)n_packet)->sum3 = 0;
				((NotifyMsg3*)n_packet)->count3 = 0;
				((NotifyMsg3*)n_packet)->groupID3 = 3;
			}
			else if (groupID == 2)
			{

				((NotifyMsg3*)n_packet)->sum = 0;
				((NotifyMsg3*)n_packet)->count = 0;
				((NotifyMsg3*)n_packet)->groupID = 1;

				((NotifyMsg3*)n_packet)->sum2 = data;
				((NotifyMsg3*)n_packet)->count2 = 1;
				((NotifyMsg3*)n_packet)->groupID2 = 2;

				((NotifyMsg3*)n_packet)->sum3 = 0;
				((NotifyMsg3*)n_packet)->count3 = 0;
				((NotifyMsg3*)n_packet)->groupID3 = 3;
			}
			else
			{

				((NotifyMsg3*)n_packet)->sum = 0;
				((NotifyMsg3*)n_packet)->count = 0;
				((NotifyMsg3*)n_packet)->groupID = 1;

				((NotifyMsg3*)n_packet)->sum2 = 0;
				((NotifyMsg3*)n_packet)->count2 = 0;
				((NotifyMsg3*)n_packet)->groupID2 = 2;

				((NotifyMsg3*)n_packet)->sum3 = data;
				((NotifyMsg3*)n_packet)->count3 = 1;
				((NotifyMsg3*)n_packet)->groupID3 = 3;
			}



		}








		// Enqueue
		enqueueDone = call NotifySendQueue.enqueue(tmp);

		if (enqueueDone == SUCCESS)
		{
			if (call NotifySendQueue.size() == 1)
			{
				// Post send
				post sendNotifyTask();
			}

			//dbg("SRTreeC", "NotifyMessage enqueued successfully in NotifySendQueue.\n");
		}
		else 
		{
			dbg("SRTreeC", "NotifyMessage failed to be enqueued in NotifySendQueue.\n");
		}

		



		

	}







// 	
	event void NotifyAMSend.sendDone(message_t *msg , error_t err)
	{
		
		//dbg("SRTreeC", "\tNotify message was sent: %s \n", (err == SUCCESS) ? "True" : "False");


		
		if (!(call NotifySendQueue.empty()))
		{
			post sendNotifyTask();
		}
		
		
	}


	
	event message_t* NotifyReceive.receive(message_t *msg, void *payload, uint8_t len)
	{
		error_t enqueueDone;
		message_t tmp;
		uint16_t msource;
		
		msource = call NotifyAMPacket.source(msg);
		
		//dbg("SRTreeC", "\tNotify message received from %u\n", msource);


		// Save message 
		atomic{
	
			memcpy(&tmp, msg, sizeof(message_t));
		}

		// enqueue message
		enqueueDone = call NotifyReceiveQueue.enqueue(tmp);
		
		if (enqueueDone == SUCCESS)
		{
			// post task
			post receiveNotifyTask();
		}
		else
		{	
			// error
			dbg("SRTreeC","NotifyMsg enqueue failed!!!\n");
			
		}
		

		return msg;
	}



































	

	
	////////////// Tasks implementations //////////////////////////////
	task void sendRoutingTask()
	{

		error_t sendDone;
		
		// Routing message was not queued
		if (call RoutingSendQueue.empty())
		{
			dbg("SRTreeC","sendRoutingTask(): Queue is empty!\n");

			return;
		}
		
		radioRoutingSendPkt = call RoutingSendQueue.dequeue();
		

		sendDone = call RoutingAMSend.send(AM_BROADCAST_ADDR, &radioRoutingSendPkt, sizeof(RoutingMsg));
		

		if (sendDone== SUCCESS)
		{
			
			//dbg("SRTreeC","sendRoutingTask(): Propagating routing message.\n");

		}
		else
		{
			dbg("SRTreeC","Propagating routing message failed.\n");

		}
	}

	////////////////////////////////////////////////////////////////////
	//*****************************************************************/
	///////////////////////////////////////////////////////////////////
	/**
	 * dequeues a message and processes it
	 */
	
	task void receiveRoutingTask()
	{
		uint8_t payload_length;
		uint16_t msg_source, offset;
		message_t radioRoutingRecPkt;

		// dequeue message
		radioRoutingRecPkt = call RoutingReceiveQueue.dequeue();
		
		// payload length
		payload_length = call RoutingPacket.payloadLength(&radioRoutingRecPkt);
		
		//dbg("SRTreeC","ReceiveRoutingTask(): length=%u \n", payload_length);

		// find message source
		msg_source = call RoutingAMPacket.source(&radioRoutingRecPkt);

		// processing of radioRoutingRecPkt			
		if(payload_length == sizeof(RoutingMsg))
		{		
			//dbg("RoutingMsg", "Node: %d, Group: %d\n", TOS_NODE_ID, groupID);

			// If it has no parent.
			if ((parentID < 0) || (parentID >= 65535))
			{

				RoutingMsg *mpkt = (RoutingMsg*)(call RoutingPacket.getPayload(&radioRoutingRecPkt, payload_length));
			
				//dbg("SRTreeC", "receiveRoutingTask():senderID= %d , depth= %d \n", msg_source, mpkt->depth);
				

				// tote den exei akoma patera
				RANDOM_NUM = mpkt->total_groups;
				groupID = (TOS_NODE_ID % mpkt->total_groups) + 1;
				parentID = msg_source;
				curdepth = mpkt->depth + 1;
				
				//dbg("RoutingMsg", "RandomNumber recieved: %d\n", mpkt->total_groups);
				dbg("RoutingMsg" , "New parent for NodeID= %d : curdepth= %d, group= %d, parentID= %d\n", TOS_NODE_ID, curdepth, groupID, parentID);

				


				// ************forward routing message.
				//call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);
				
				call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);

			}
			else
			{
				// Mote already has a parent
				//dbg("SRTreeC", "NodeID= %d : Already h as a parent: curdepth= %d, parentID= %d, group= %d\n", TOS_NODE_ID, curdepth, parentID, groupID);
			}

			//*************
			//call NotifyDataTimer.startPeriodicAt(TIMER_PERIOD_MILLI-BOOT_TIME-(TIMER_FAST_PERIOD*curdepth), TIMER_PERIOD_MILLI);
			//call NotifyDataTimer.startOneShot(BOOT_TIME-(TIMER_FAST_PERIOD*curdepth));
						
			offset =  ((call Random.rand16()) % TIMER_FAST_PERIOD/2) + 1;
			call NotifyDataTimer.startPeriodicAt(-BOOT_TIME-(TIMER_FAST_PERIOD*curdepth) + offset , TIMER_PERIOD_MILLI);

			// forward routing message.
			//call RoutingMsgTimer.startOneShot(TIMER_FAST_PERIOD);
		}
		else
		{
			dbg("SRTreeC", "receiveRoutingTask():Empty message!!!\n");

			return;
		}
		
	}




























	/**
	 * dequeues a message and sends it
	 */
	task void sendNotifyTask()
	{
		uint8_t payload_length, node_data;
		uint16_t mdest;
		uint16_t sum, sum2, sum3;
		uint8_t count, count2, count3, i;
		void *payload;
		void *msg_pckt;
		error_t sendDone;
		message_t tmp;
		
		

		if (call NotifySendQueue.empty())
		{
			dbg("SRTreeC","sendNotifyTask(): Q is empty!\n");

			return;
		}

		// Dequeue message
		radioNotifySendPkt = call NotifySendQueue.dequeue();

		// Get payload length
		payload_length = call NotifyPacket.payloadLength(&radioNotifySendPkt);

		// Get payload
		if (RANDOM_NUM == 1)
		{
			payload = (NotifyMsg *) (call NotifyPacket.getPayload(&radioNotifySendPkt, payload_length));
			// error case
			if (payload_length != sizeof(NotifyMsg))
			{
				dbg("SRTreeC", "\t\t sendNotifyTask(): Not valid message.\n");
				return;
			}

			// Save measurement
			node_data = ((NotifyMsg *)payload)->sum;
		}
		else if (RANDOM_NUM == 2)
		{
			payload = (NotifyMsg2 *) (call NotifyPacket.getPayload(&radioNotifySendPkt, payload_length));
			// error case
			if (payload_length != sizeof(NotifyMsg2))
			{
				dbg("SRTreeC", "\t\t sendNotifyTask(): Not valid message.\n");
				return;
			}

			// Save measurement
			if (groupID == 1)
			{
				node_data = ((NotifyMsg2 *)payload)->sum;
			}
			else
			{
				node_data = ((NotifyMsg2 *)payload)->sum2;
			}
		}
		else 
		{
			payload = (NotifyMsg3 *) (call NotifyPacket.getPayload(&radioNotifySendPkt, payload_length));
			// error case
			if (payload_length != sizeof(NotifyMsg3))
			{
				dbg("SRTreeC", "\t\t sendNotifyTask(): Not valid message.\n");
				return;
			}

			// Save measurement
			if (groupID == 1)
			{
				node_data = ((NotifyMsg3 *)payload)->sum;
			}
			else if (groupID == 2)
			{
				node_data = ((NotifyMsg3 *)payload)->sum2;
			}
			else 
			{
				node_data = ((NotifyMsg3 *)payload)->sum3;
			}
		}







		// error case
		if (msg_pckt == NULL)
		{
			dbg("SRTreeC", "sendNotifyTask: Error: no valid payload.\n");
			return;
		}

		if (RANDOM_NUM == 1)
		{
			// calc SUM
			sum = node_data;
			count = 1;

			for (i = 0; i < MAX_CHILDREN && children[i].childID != 0; i++)
			{
				sum += children[i].sum;
				count += children[i].count;
			}

			// Send the Packet.
			call NotifyPacket.setPayloadLength(&tmp, sizeof(NotifyMsg));
			msg_pckt = (NotifyMsg *) (call NotifyPacket.getPayload(&tmp, sizeof(NotifyMsg)));


			if (TOS_NODE_ID != 0)
			{

				// Copy message
				atomic{
					call NotifyAMPacket.setDestination(&tmp, parentID);
					
					((NotifyMsg *)msg_pckt)->sum = sum;
					((NotifyMsg *)msg_pckt)->count = count;
					((NotifyMsg *)msg_pckt)->groupID = groupID;
					
					memcpy(&radioNotifySendPkt, &tmp, sizeof(message_t));
				}

				// Set destination
				mdest = call NotifyAMPacket.destination(&radioNotifySendPkt);

				payload_length = call NotifyPacket.payloadLength(&radioNotifySendPkt);

				// Send message
				sendDone = call NotifyAMSend.send(mdest, &radioNotifySendPkt, payload_length);

				if (sendDone == SUCCESS)
				{
					//dbg("SRTreeC", "sendNotifyTask(): Send message returned success!\n");
				}
				else
				{
					// error
					dbg("SRTreeC", "sending notify message failed.\n");
				}
			}

			else 
			{
				// Print All results. ?/ Not sure perhaps Recieve.
			}
		}
		else if (RANDOM_NUM == 2)
		{
			sum = 0;
			sum2 = 0;
			count = 0;
			count2 = 0;

			for (i = 0; i < MAX_CHILDREN; i++)
			{
				if (children[i].childID == 0)
				{
					continue;
				}
				if (children[i].groupID == 2)
				{
					sum += children[i].sum;
					count += children[i].count;
					//dbg("SRTreeC", "i is: %d\n", i);
					//dbg("SRTreeC", "childgroupdID: %d, childID: %d, childSum: %d, childCount: %d\n", children[i].groupID, children[i].childID, children[i].sum, children[i].count);
					//dbg("SRTreeC", "Total sum: %d, Total count: %d\n", sum, count);
				}
				else
				{
					sum2 += children[i].sum2;
					count2 += children[i].count2;
					//dbg("SRTreeC", "childID: %d, childSum: %d, childCount: %d\n", children[i].childID, children[i].sum2, children[i].count2);
					//dbg("SRTreeC", "Total sum: %d, Total count: %d\n", sum2, count2);
				}
			}

			if (groupID == 1)
			{
				sum += node_data;
				count += 1;
				//dbg("SRTreeC", "Total sum with our measurement: %d, %d\n", sum, count);
			}
			else
			{
				sum2 += node_data;
				count2 += 1;
				//dbg("SRTreeC", "Total sum with our measurement: %d, %d\n", sum2, count2);
			}


			// Send the Packet.
			call NotifyPacket.setPayloadLength(&tmp, sizeof(NotifyMsg2));
			msg_pckt = (NotifyMsg2 *) (call NotifyPacket.getPayload(&tmp, sizeof(NotifyMsg2)));


			if (TOS_NODE_ID != 0)
			{

				// Copy message
				atomic{
					call NotifyAMPacket.setDestination(&tmp, parentID);
				
					((NotifyMsg2 *)msg_pckt)->sum = sum;
					((NotifyMsg2 *)msg_pckt)->count = count;
					((NotifyMsg2 *)msg_pckt)->groupID = ((NotifyMsg3 *)payload)->groupID;

					((NotifyMsg2 *)msg_pckt)->sum2 = sum2;
					((NotifyMsg2 *)msg_pckt)->count2 = count2;
					((NotifyMsg2 *)msg_pckt)->groupID2 = ((NotifyMsg3 *)payload)->groupID2;
					
		

					
					memcpy(&radioNotifySendPkt, &tmp, sizeof(message_t));
				}

				// Set destination
				mdest = call NotifyAMPacket.destination(&radioNotifySendPkt);

				payload_length = call NotifyPacket.payloadLength(&radioNotifySendPkt);

				// Send message
				sendDone = call NotifyAMSend.send(mdest, &radioNotifySendPkt, payload_length);

				if (sendDone == SUCCESS)
				{
					//dbg("SRTreeC", "sendNotifyTask(): Send message returned success!\n");
				}
				else
				{
					// error
					dbg("SRTreeC", "sending notify message failed.\n");
				}
			}
			else 
			{
				// Print All results. ?/ Not sure perhaps Recieve.
			}

		}
		else 
		{
			sum = 0;
			sum2 = 0;
			sum3 = 0;
			count = 0;
			count2 = 0;
			count3 = 0;
			

			for (i = 0; i < MAX_CHILDREN && children[i].childID != 0; i++)
			{
				if (children[i].groupID == 1)
				{
					sum += children[i].sum;
					count += children[i].count;
				}
				else if (children[i].groupID == 2)
				{
					sum2 += children[i].sum2;
					count2 += children[i].count2;
				}
				else
				{
					sum3 += children[i].sum3;
					count3 += children[i].count3;
				}
			}

			if (groupID == 1)
			{
				sum += node_data;
				count += 1;
			}
			else if (groupID == 2)
			{
				sum2 += node_data;
				count2 += 1;
			}
			else
			{
				sum3 += node_data;
				count3 += 1;
			}

			// Send the Packet.
			call NotifyPacket.setPayloadLength(&tmp, sizeof(NotifyMsg3));
			msg_pckt = (NotifyMsg3 *) (call NotifyPacket.getPayload(&tmp, sizeof(NotifyMsg3)));


			if (TOS_NODE_ID != 0)
			{

				// Copy message
				atomic{
					call NotifyAMPacket.setDestination(&tmp, parentID);
					
					((NotifyMsg3 *)msg_pckt)->sum = sum;
					((NotifyMsg3 *)msg_pckt)->count = count;
					((NotifyMsg3 *)msg_pckt)->groupID = ((NotifyMsg3 *)payload)->groupID;

					((NotifyMsg3 *)msg_pckt)->sum2 = sum2;
					((NotifyMsg3 *)msg_pckt)->count2 = count2;
					((NotifyMsg3 *)msg_pckt)->groupID2 = ((NotifyMsg3 *)payload)->groupID2;

					((NotifyMsg3 *)msg_pckt)->sum3 = sum3;
					((NotifyMsg3 *)msg_pckt)->count3 = count3;
					((NotifyMsg3 *)msg_pckt)->groupID3 = ((NotifyMsg3 *)payload)->groupID3;
					
					memcpy(&radioNotifySendPkt, &tmp, sizeof(message_t));
				}

				// Set destination
				mdest = call NotifyAMPacket.destination(&radioNotifySendPkt);

				payload_length = call NotifyPacket.payloadLength(&radioNotifySendPkt);

				// Send message
				sendDone = call NotifyAMSend.send(mdest, &radioNotifySendPkt, payload_length);

				if (sendDone == SUCCESS)
				{
					//dbg("SRTreeC", "sendNotifyTask(): Send message returned success!\n");
				}
				else
				{
					// error
					dbg("SRTreeC", "sending notify message failed.\n");
				}
			}
			else 
			{
				// Print All results. ?/ Not sure perhaps Recieve.
			}
		}






		
		

	
	}


////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////	
	 
	task void receiveNotifyTask()
	{
		message_t tmp;
		message_t radioNotifyRecPkt;
		uint8_t len, i;
		uint16_t msource;
		void *msg;

		uint16_t total_sum = 0;
		uint16_t total_count = 0;
		uint16_t avg = 0;
		
		

		radioNotifyRecPkt = call NotifyReceiveQueue.dequeue();
		
		len = call NotifyPacket.payloadLength(&radioNotifyRecPkt);
		

		msource = call NotifyAMPacket.source(&radioNotifyRecPkt);

		if (RANDOM_NUM == 1)
		{
			msg = (NotifyMsg *) (call NotifyPacket.getPayload(&radioNotifyRecPkt, len));
					
			for (i = 0; i < MAX_CHILDREN; i++)
			{

				//dbg("SRTreeC", "childID: %d, msource: %d\n", children[i].childID, msource);
				if (children[i].childID == msource || children[i].childID == 0)
				{
					if (children[i].childID == 0)
					{
						children[i].childID = msource;
					}

					children[i].sum = ((NotifyMsg *)msg)->sum;
					children[i].count = ((NotifyMsg *)msg)->count;
					children[i].groupID = ((NotifyMsg *)msg)->groupID;

					dbg("SRTreeC" , "GroupID: %d, Node %d received from childID: %d, sum:%d, count: %d\n", ((NotifyMsg *)msg)->groupID, TOS_NODE_ID, children[i].childID, children[i].sum, children[i].count);


					break;
				}
			}

			if (TOS_NODE_ID == 0)
			{
				// print average.
			}
		}
		else if (RANDOM_NUM == 2)
		{
			msg = (NotifyMsg2 *) (call NotifyPacket.getPayload(&radioNotifyRecPkt, len));
					
			for (i = 0; i < MAX_CHILDREN; i++)
			{

				//dbg("SRTreeC", "childID: %d, msource: %d\n", children[i].childID, msource);
				if (children[i].childID == msource || children[i].childID == 0)
				{
					if (children[i].childID == 0)
					{
						children[i].childID = msource;
					}

					children[i].sum = ((NotifyMsg2 *)msg)->sum;
					children[i].count = ((NotifyMsg2 *)msg)->count;
					children[i].groupID = ((NotifyMsg2 *)msg)->groupID;

					children[i].sum2 =  ((NotifyMsg2 *) msg)->sum2;
					children[i].count2 = ((NotifyMsg2 *)msg)->count2;
					children[i].groupID2 = ((NotifyMsg2 *)msg)->groupID2;

					//dbg("SRTreeC", "i: %d\n", i);
					dbg("SRTreeC" , "GroupID: %d, Node %d received from childID: %d, sum:%d, count: %d\n", ((NotifyMsg2 *)msg)->groupID, TOS_NODE_ID, children[i].childID, children[i].sum, children[i].count);
					dbg("SRTreeC" , "GroupID: %d, Node %d received from childID: %d, sum:%d, count: %d\n", ((NotifyMsg2 *)msg)->groupID2, TOS_NODE_ID, children[i].childID, children[i].sum2, children[i].count2);


					break;
				}
			}
		}
		else
		{
			msg = (NotifyMsg3 *) (call NotifyPacket.getPayload(&radioNotifyRecPkt, len));
					
			for (i = 0; i < MAX_CHILDREN; i++)
			{

				//dbg("SRTreeC", "childID: %d, msource: %d\n", children[i].childID, msource);
				if (children[i].childID == msource || children[i].childID == 0)
				{
					if (children[i].childID == 0)
					{
						children[i].childID = msource;
					}

					children[i].sum = ((NotifyMsg3 *)msg)->sum;
					children[i].count = ((NotifyMsg3 *)msg)->count;
					children[i].groupID = ((NotifyMsg3 *)msg)->groupID;

					children[i].sum2 = ((NotifyMsg3 *)msg)->sum2;
					children[i].count2 = ((NotifyMsg3 *)msg)->count2;
					children[i].groupID2 = ((NotifyMsg3 *)msg)->groupID2;

					children[i].sum3 = ((NotifyMsg3 *)msg)->sum3;
					children[i].count3 = ((NotifyMsg3 *)msg)->count3;
					children[i].groupID3 = ((NotifyMsg3 *)msg)->groupID3;

					dbg("SRTreeC" , "GroupID: %d, Node %d received from childID: %d, sum:%d, count: %d\n", ((NotifyMsg3 *)msg)->groupID, TOS_NODE_ID, children[i].childID, children[i].sum, children[i].count);
					dbg("SRTreeC" , "GroupID: %d, Node %d received from childID: %d, sum:%d, count: %d\n", ((NotifyMsg3 *)msg)->groupID2, TOS_NODE_ID, children[i].childID, children[i].sum2, children[i].count2);
					dbg("SRTreeC" , "GroupID: %d, Node %d received from childID: %d, sum:%d, count: %d\n", ((NotifyMsg3 *)msg)->groupID3, TOS_NODE_ID, children[i].childID, children[i].sum3, children[i].count3);


					break;
				}
			}
		}

		

		if (TOS_NODE_ID == 0)
		{
			for (i = 0; i < MAX_CHILDREN; i++)
			{
				if (children[i].childID != 0 && children[i].groupID == 1)
				{
					total_sum += children[i].sum;
					total_count += children[i].count;
				}
			}

			if (total_count != 0)
			{
				avg = (uint16_t)(total_sum / total_count);
			}
			dbg("SRTreeC", "GROUP 1 Results are:\n\t\tSUM: %d\tCOUNT: %d\t-> AVG: %d\n", total_sum, total_count, avg);




			total_sum = 0;
			total_count = 0;
			avg = 0;

			for (i = 0; i < MAX_CHILDREN; i++)
			{

				if (children[i].childID != 0 && children[i].groupID == 2)
				{
					total_sum += children[i].sum;
					total_count += children[i].count;
				}
			}

			if (total_count != 0)
			{
				avg = (uint16_t) (total_sum / total_count);
			}
			dbg("SRTreeC", "GROUP 2 Results are:\n\t\tSUM: %d\tCOUNT: %d\t-> AVG: %d\n", total_sum, total_count, avg);





			total_sum = 0;
			total_count = 0;
			avg = 0;

			for (i = 0; i < MAX_CHILDREN; i++)
			{
				if (children[i].childID != 0 && children[i].groupID == 3)
				{
					total_sum += children[i].sum;
					total_count += children[i].count;
				}
			}

			if (total_count != 0)
			{
				avg = (uint16_t) (total_sum / total_count);
			}
			dbg("SRTreeC", "GROUP 3 Results are:\n\t\tSUM: %d\tCOUNT: %d\t-> AVG: %d\n", total_sum, total_count, avg);


		}

		//dbg("SRTreeC","ReceiveNotifyTask(): len=%u \n", len);
		





		
	}





















	




	

}