#!/usr/sbin/dtrace -s

isim*:::request-block
{
    @["blocked requests"] = count(); 
}

isim*:::request-nonblock
{
    @["non blocked requests"] = count(); 
}

isim*:::request-start
{
    @["requests started"] = count(); 
}

isim*:::request-done
{
    @["requests done"] = count(); 
}

isim*:::persist-start
{
    @["persistent writes started"] = count(); 
}

isim*:::persist-done
{
    @["persistent writes done"] = count(); 
} 
tick-60s {
    exit(0); 
}
