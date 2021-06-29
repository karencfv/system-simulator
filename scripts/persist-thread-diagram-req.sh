#!/usr/sbin/dtrace -s

#pragma D option flowindent

isim*:::persist-async-start
{
	self->follow = timestamp;
}

isim*:::persist-done
/self->follow/
{
    trace(timestamp - self->follow);
    self->follow = 0;
}
tick-10s {
	printf("Flowcharts of all writes to persistent storage taken in ten seconds represented in nanoseconds:");
    exit(0); 
}