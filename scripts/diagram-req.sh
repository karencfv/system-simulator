#!/usr/sbin/dtrace -s

#pragma D option flowindent

isim*:::request-start
{
	follow[arg0] = timestamp;
}

isim*:::persist-start,
isim*:::persist-done
/follow[arg0]/
{
    trace(timestamp - follow[arg0]);
}

isim*:::request-done
/follow[arg0]/
{
    trace(timestamp - follow[arg0]);
    follow[arg0] = 0;
    exit(0);
}
