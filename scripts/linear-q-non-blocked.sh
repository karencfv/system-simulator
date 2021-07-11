#!/usr/sbin/dtrace -s

#pragma D option quiet

isim*:::request-nonblock
{
	follow[arg0] = vtimestamp;
}

isim*:::request-done
/follow[arg0] != 0/
{
	@histogram["Request lifetimes for non blocked requests from the time they are queued in microseconds"] =
	/*
	* To be used with a single client. No requests being blocked.
	*	lquantize((vtimestamp - follow[arg0]) / 1000, 0, 100000, 50);
	*/

	/*
	* To be used with light/medium load (15 - 135 clients). Half or more requests being blocked.
	*/
		lquantize((vtimestamp - follow[arg0]) / 1000, 0, 100000, 100);
	
	follow[arg0] = 0;
}

tick-60s {
   exit(0); 
}