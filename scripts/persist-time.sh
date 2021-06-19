#!/usr/sbin/dtrace -s

#pragma D option quiet
isim*:::persist-async-start
{
	self->t = timestamp;
}

isim*:::persist-done
/self->t != 0/
{
	/*
	 * Uncomment if you wish to see how long every write to the persistent storage took.
	 * printf("%d/%d spent %d nsecs to finish persistent storage action lifetime\n",
	 *    pid, tid, timestamp - self->t);
	 */
	@totalwrts["total writes"] = count();
	@avgtime["average write"] = avg(timestamp - self->t);
	@maxtime["max write"] = max(timestamp - self->t);
	@mintime["min write"] = min(timestamp - self->t);
	@histogram["visualisation of writes"] = quantize(timestamp - self->t);
	self->t = 0;
}
tick-60s {
	printf("Summary of all writes to persistent storage taken in one minute represented in nanoseconds:");
    exit(0); 
}
