#ifndef SIMPLEROUTINGTREE_H
#define SIMPLEROUTINGTREE_H


enum{
	SENDER_QUEUE_SIZE=5,
	RECEIVER_QUEUE_SIZE=3,
	
	AM_SIMPLEROUTINGTREEMSG=22,
	AM_ROUTINGMSG=22,
	AM_NOTIFYMSG=12,

	
	// Epoch duration
	TIMER_PERIOD_MILLI=65*1024,
	TIMER_FAST_PERIOD=256,
	TIMER_ROUTING_DURATION=5*1024,	// Routing Time


	// Boot duration (simulation)
	BOOT_TIME=10*1024,

	MAX_CHILDREN=8,
};

typedef nx_struct Node 
{
	nx_uint16_t childID;

	nx_uint16_t sum;
	nx_uint8_t count;
	nx_uint8_t groupID;

	nx_uint16_t sum2;
	nx_uint8_t count2;
	nx_uint8_t groupID2;

	nx_uint16_t sum3;
	nx_uint8_t count3;
	nx_uint8_t groupID3;

} Node;


typedef nx_struct RoutingMsg
{
	nx_uint8_t depth;
	nx_uint8_t total_groups;

} RoutingMsg;

typedef nx_struct NotifyMsg
{
	nx_uint16_t sum;
	nx_uint8_t count;
	nx_uint8_t groupID;

} NotifyMsg;

typedef nx_struct NotifyMsg2
{
	nx_uint16_t sum;
	nx_uint8_t count;
	nx_uint8_t groupID;

	nx_uint16_t sum2;
	nx_uint8_t count2;
	nx_uint8_t groupID2;

} NotifyMsg2;

typedef nx_struct NotifyMsg3
{
	nx_uint16_t sum;
	nx_uint8_t count;
	nx_uint8_t groupID;

	nx_uint16_t sum2;
	nx_uint8_t count2;
	nx_uint8_t groupID2;

	nx_uint16_t sum3;
	nx_uint8_t count3;
	nx_uint8_t groupID3;

} NotifyMsg3;




#endif
