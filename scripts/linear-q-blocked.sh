#!/usr/sbin/dtrace -s

#pragma D option quiet

isim*:::request-block
{
	follow[arg0] = vtimestamp;
}

isim*:::request-done
/follow[arg0] != 0/
{
	@histogram["Request lifetimes for blocked requests from the time they are blocked in microseconds"] =
	/*
	* To be used with light load (15 clients). About half requests being blocked.
	*	lquantize((vtimestamp - follow[arg0]) / 1000, 0, 100000, 100);
	*/

	/*
	* To be used with medium load (125 clients). About half requests being blocked.
	*	lquantize((vtimestamp - follow[arg0]) / 1000, 0, 10000000, 200);
	*/

	/*
	* To be used with medium load (135 clients). Most requests being blocked.
	*	lquantize((vtimestamp - follow[arg0]) / 1000, 0, 10000000, 1000);
	*/

	/*
	* To be used with heavy load (1000 clients). All requests being blocked.
	*/
		lquantize((vtimestamp - follow[arg0]) / 1000, 0, 10000000, 50000);
	
	follow[arg0] = 0;
}

tick-60s {
   exit(0); 
}