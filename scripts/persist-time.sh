#!/usr/sbin/dtrace -s

#pragma D option quiet
isim*:::persist-start
{
	follow[arg0] = timestamp;
}

isim*:::persist-done
/follow[arg0] != 0/
{
	/*
	 * Uncomment if you wish to see how long every write to the persistent storage took.
	 * printf("%d/%d spent %d nsecs to finish persistent storage action lifetime\n",
	 *    pid, tid, timestamp - follow[arg0]);
	 */
	@totalwrts["total writes"] = count();
	@avgtime["average write"] = avg(timestamp - follow[arg0]);
	@maxtime["max write"] = max(timestamp - follow[arg0]);
	@mintime["min write"] = min(timestamp - follow[arg0]);
	@histogram["visualisation of writes"] = quantize(timestamp - follow[arg0]);
	follow[arg0] = 0;
}
tick-60s {
	printf("Summary of all writes to persistent storage taken in one minute represented in nanoseconds:");
    exit(0); 
}
