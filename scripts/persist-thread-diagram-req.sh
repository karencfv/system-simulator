#!/usr/sbin/dtrace -s

#pragma D option flowindent

isim*:::persist-async-start
{
	follow[arg0] = timestamp;
}

isim*:::persist-done
/follow[arg0]/
{
    trace(timestamp - follow[arg0]);
    follow[arg0] = 0;
}
tick-10s {
	printf("Flowcharts of all writes to persistent storage taken in ten seconds represented in nanoseconds:");
    exit(0); 
}