#!/usr/sbin/dtrace -s

#pragma D option flowindent

isim*:::request-start
{
	self->follow = timestamp;;
}

isim*:::persist-start,
isim*:::persist-done
/self->follow/
{
    trace(timestamp - self->follow);
}

isim*:::request-done
/self->follow/
{
    trace(timestamp - self->follow);
    self->follow = 0;
    exit(0);
}
