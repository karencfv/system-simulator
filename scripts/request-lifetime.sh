#!/usr/sbin/dtrace -s

#pragma D option quiet

isim*:::request-start
{
	self->t = timestamp;
}

isim*:::request-done
/self->t != 0/
{
	/*
	 * Uncomment if you wish to see how long every request lifetime took.
	 * printf("%d/%d took %d nsecs to finish request lifetime\n",
	 *    pid, tid, timestamp - self->t);
	 */
	@totalrqs["total requests"] = count();
	@avgtime["average request lifetime"] = avg(timestamp - self->t);
	@maxtime["max request lifetime"] = max(timestamp - self->t);
	@mintime["min request lifetime"] = min(timestamp - self->t);
	@histogram["request lifetimes visualisation"] = quantize(timestamp - self->t);
	self->t = 0;
}

tick-60s {
	printf("Summary of all request lifetimes taken in one minute represented in nanoseconds:");
    exit(0); 
}