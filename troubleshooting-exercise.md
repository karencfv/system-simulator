# System simulator troubleshooting rundown

## Problem statement

The following observations are taken using a MacBook Air (M1, 2020) with 16GB RAM.

Starting from a single client, after a slight increase in load (8 clients sunning in parallel) the system begins to block requests. As the load increases, the blockage becomes worse until at about 135 clients running in parallel, when all requests are blocked.

### Non issues

- Packet delay variation (or jitter). There is no correlation between the amount of clients and the variance in network delay. Also, all requests are going through, so you can rule out things like network packet drops due to kernel TCP backlog overflow.

- All tests are run in a controlled environment, so the issue of noisy neighbours can be ruled out. 

### Open questions

- What is the system storing? Is the system storing elements that are all the same size? Or are they all different sizes?

## System diagram

![image](./assets/system-simulator-diagram.png)

## Troubleshooting

Below are the results of all the readings I have taken. As a rule of thumb I normally take 3 samples of data per debugging script, to rule out glitches or a result that looks wildly different for some reason. In this case there were no major differences each time I ran the scripts, so for brevity's sake I have only included one of the runs per different load amount.

### Summary of requests

I ran a script which counts the total requests for each of `request-block`, `request-nonblock`, `requests-start`, `request-done`, `persist-started`, and `persist-done` during a minute under different load.

These are my findings:

- Regardless of load, all requests are completed.
- Under very light load all requests go through without being blocked.
- While still on light load (15 clients), slightly less than half of the requests are getting blocked.
- Under medium load (125 clients), little less than 75% of requests are blocked.
- When I increased the medium load slightly (135 clients), most requests are blocked (i.e. 8 out of 7733 are not blocked)
- Under heavy load (1000 clients), all requests are blocked.

Results of running the [request count](./scripts/count.sh) DTrace script on different loads:

<details>

#### Running the count script using 1 client

```console
CPU     ID                    FUNCTION:NAME
  4   5281                        :tick-60s 

  non blocked requests                                             60
  persistent writes done                                           60
  persistent writes started                                        60
  requests done                                                    60
  requests started                                                 60
```

#### Running the count script using 15 clients

```console
CPU     ID                    FUNCTION:NAME
  4   5281                        :tick-60s 

  blocked requests                                                283
  non blocked requests                                            617
  persistent writes done                                          898
  persistent writes started                                       900
  requests done                                                   900
  requests started                                                900
```

#### Running the count script using 125 clients

```console
CPU     ID                    FUNCTION:NAME
  6   5281                        :tick-60s 

  blocked requests                                               2802
  non blocked requests                                           4622
  requests done                                                  7423
  persistent writes started                                      7424
  requests started                                               7424
  persistent writes done                                         7425
```

#### Running the count script using 135 clients

```console
CPU     ID                    FUNCTION:NAME
  5   5281                        :tick-60s 

  non blocked requests                                              8
  blocked requests                                               7733
  requests done                                                  7739
  persistent writes done                                         7740
  persistent writes started                                      7740
  requests started                                               7740
```

#### Running the count script using 1000 clients

```console
CPU     ID                    FUNCTION:NAME
  4   5281                        :tick-60s 

  blocked requests                                               7679
  requests started                                               7679
  requests done                                                  7680
  persistent writes done                                         7681
  persistent writes started                                      7681
```
</details>

## Request lifetime duration per thread

I took request lifetime duration readings for 1 minute under different load. These are my findings:

- When running 1000 clients in parallel, the total of requests processed goes down to ~3800 from ~4666, which is the result of running 125 clients (at 125 clients about 25% of requests are not being blocked).
- The average on lighter load is ~6608681ns which is higher than the average on medium (15 clients and ~3991609ns), high (125 clients and ~4760868ns), and max (1000 clients and ~3384652ns).

Results of running the [request lifetime](./scripts/request-lifetime.sh) DTrace script on different loads:
<details>

#### Running the request lifetimes script using 1 client (no requests are blocked)

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                   60
  average request lifetime                                    6565760
  max request lifetime                                        8324958
  min request lifetime                                        5459416
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
         2097152 |                                         0        
         4194304 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 60       
         8388608 |                                         0 
```

#### Running the request lifetimes script using 15 clients (some requests are blocked)

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                  176
  average request lifetime                                    3829997
  max request lifetime                                        8240208
  min request lifetime                                         265125
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
          131072 |                                         0        
          262144 |                                         2        
          524288 |                                         1        
         1048576 |@@@@@@@@@@                               44       
         2097152 |@@@@@@@@@@@@                             52       
         4194304 |@@@@@@@@@@@@@@@@@@                       77       
         8388608 |                                         0
```

#### Running the request lifetimes script using 125 clients (some requests are blocked)

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                 4666
  average request lifetime                                    4697868
  max request lifetime                                       23316875
  min request lifetime                                          16875
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
            8192 |                                         0        
           16384 |                                         11       
           32768 |                                         13       
           65536 |                                         1        
          131072 |                                         15       
          262144 |@                                        62       
          524288 |                                         42       
         1048576 |@@@@@                                    586      
         2097152 |@@@@@@@@@@@@@                            1519     
         4194304 |@@@@@@@@@@@@@@@@@@                       2128     
         8388608 |@@                                       274      
        16777216 |                                         15       
        33554432 |                                         0
```

#### Running the request lifetimes script using 135 clients (all requests are blocked)

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                 3961
  average request lifetime                                    4409304
  max request lifetime                                       33164500
  min request lifetime                                          32708
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
            8192 |                                         0        
           16384 |                                         1        
           32768 |                                         1        
           65536 |                                         12       
          131072 |@                                        78       
          262144 |@@                                       191      
          524288 |@                                        75       
         1048576 |@@@@@@@                                  731      
         2097152 |@@@@@@@@@@@@@@@                          1491     
         4194304 |@@@@@@@@@                                885      
         8388608 |@@@@                                     425      
        16777216 |@                                        71       
        33554432 |                                         0 
```

#### Running the request lifetimes script using 1000 clients (all requests are blocked)

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                 3775
  average request lifetime                                    3403925
  max request lifetime                                       38066959
  min request lifetime                                          59834
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
           16384 |                                         0        
           32768 |                                         3        
           65536 |                                         14       
          131072 |@@@@@@@@@@                               988      
          262144 |@@@@                                     360      
          524288 |                                         15       
         1048576 |@@@@@                                    500      
         2097152 |@@@@@@@@@                                844      
         4194304 |@@@@@@@                                  681      
         8388608 |@@@                                      301      
        16777216 |@                                        65       
        33554432 |                                         4        
        67108864 |                                         0
```

</details>

## Writing to persistent storage duration per thread

I took persistent store transaction duration readings for 1 minute under different load. These are my findings:

- Once all requests are blocked, the total number of write transactions decreases. ~5904 when running 135 clients in parallel, and ~4282 when running 1000 clients.

- Under high load after most requests start being blocked, the latency increases slightly and plateaus.

- It seems that during medium load when several requests are blocked (50% - 75%), the persistent store transactions take less time to complete (this may be due to the random number generator for the range).

Results of running the [persistent store transactions](./scripts/persist-time.sh) DTrace script on different loads:

<details>

#### Running persist-time script using 1 client

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                     58
  average write                                            1056537086
  max write                                                4096332625
  min write                                                  55025666
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
        16777216 |                                         0        
        33554432 |@@@@@@@@@@@@@@                           20       
        67108864 |@@@@                                     6        
       134217728 |                                         0        
       268435456 |                                         0        
       536870912 |@@@@@                                    7        
      1073741824 |@@@@@@@@@@@@                             18       
      2147483648 |@@@@@                                    7        
      4294967296 |                                         0
```

#### Running persist-time script using 15 clients

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                    358
  average write                                              95680837
  max write                                                4158929375
  min write                                                     30542
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
            8192 |                                         0        
           16384 |                                         1        
           32768 |                                         0        
           65536 |                                         2        
          131072 |                                         3        
          262144 |                                         2        
          524288 |                                         1        
         1048576 |@@@@@@@@                                 69       
         2097152 |@@@@@@                                   50       
         4194304 |@@                                       18       
         8388608 |@                                        7        
        16777216 |                                         0        
        33554432 |@@@@@@@@@@@@@@@@@@@@                     180      
        67108864 |@                                        8        
       134217728 |                                         0        
       268435456 |                                         0        
       536870912 |@@                                       15       
      1073741824 |                                         0        
      2147483648 |                                         2        
      4294967296 |                                         0 
```

#### Running persist-time script using 125 clients

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                   5088
  average write                                              15728164
  max write                                                 954772500
  min write                                                     18667
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
            8192 |                                         0        
           16384 |                                         1        
           32768 |                                         0        
           65536 |                                         11       
          131072 |                                         11       
          262144 |                                         2        
          524288 |                                         2        
         1048576 |@@@                                      428      
         2097152 |@@@@@@@                                  880      
         4194304 |@@@@@@@                                  919      
         8388608 |@@@@@@@@@@@@                             1467     
        16777216 |@@@@@@@@                                 1063     
        33554432 |@@                                       207      
        67108864 |                                         42       
       134217728 |                                         34       
       268435456 |                                         18       
       536870912 |                                         3        
      1073741824 |                                         0 
```

#### Running persist-time script using 135 clients

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                   5904
  average write                                              16260669
  max write                                                 518956458
  min write                                                     47500
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
           16384 |                                         0        
           32768 |                                         2        
           65536 |                                         21       
          131072 |                                         12       
          262144 |                                         4        
          524288 |                                         4        
         1048576 |@@@@                                     597      
         2097152 |@@@@@@@                                  1027     
         4194304 |@@@@@@@                                  1017     
         8388608 |@@@@@@@@@                                1375     
        16777216 |@@@@@@@@                                 1195     
        33554432 |@@@@                                     523      
        67108864 |@                                        86       
       134217728 |                                         32       
       268435456 |                                         9        
       536870912 |                                         0
```

#### Running persist-time script using 1000 clients

```console
  total writes                                                   4282
  average write                                              19894690
  max write                                                3828975459
  min write                                                     17834
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
            8192 |                                         0        
           16384 |                                         4        
           32768 |                                         4        
           65536 |                                         12       
          131072 |                                         3        
          262144 |                                         0        
          524288 |                                         0        
         1048576 |@@                                       226      
         2097152 |@@@@                                     476      
         4194304 |@@@@@@@                                  729      
         8388608 |@@@@@@@@@@@                              1163     
        16777216 |@@@@@@@@@@@                              1193     
        33554432 |@@@                                      360      
        67108864 |@                                        64       
       134217728 |                                         40       
       268435456 |                                         7        
       536870912 |                                         0        
      1073741824 |                                         0        
      2147483648 |                                         1        
      4294967296 |                                         0
```

</details>

### CPU usage

I will record CPU usage to have as a reference for when I implement a solution. This will help compare results and verify that a solution does not affect other parts of the system.

The [cpu usage](./scripts/cpu-usage.sh) scripts takes readings of the process at a set interval for a minute.

Findings:

- CPU usage spikes drastically once the blockage becomes more prevalent, ~20% under medium load (125-135 clients) and 47% under high load (1000 clients) 

<details>

#### Running CPU usage script using 1 client for 1 minute

```console
TIMESTAMP  PID    %CPU    PROCESS
13:00:25  17887   0.1 system-simulator
13:00:37  17887   0.1 system-simulator
13:00:49  17887   0.0 system-simulator
13:01:01  17887   0.0 system-simulator
13:01:13  17887   0.0 system-simulator
```

#### Running CPU usage script using 15 clients for 1 minute

```console
TIMESTAMP  PID    %CPU    PROCESS
13:12:27  18084   0.2 system-simulator
13:12:39  18084   0.3 system-simulator
13:12:51  18084   0.4 system-simulator
13:13:03  18084   0.9 system-simulator
13:13:15  18084   1.5 system-simulator
```

#### Running CPU usage script using 125 clients for 1 minute

```console
TIMESTAMP  PID    %CPU    PROCESS
13:24:44  18263  15.4 system-simulator
13:24:56  18263  18.5 system-simulator
13:25:08  18263  15.6 system-simulator
13:25:20  18263  17.8 system-simulator
13:25:32  18263  18.5 system-simulator
```

#### Running CPU usage script using 135 clients for 1 minute

```console
TIMESTAMP  PID    %CPU    PROCESS
13:26:41  18466  22.2 system-simulator
13:26:53  18466  18.7 system-simulator
13:27:05  18466  22.4 system-simulator
13:27:17  18466  20.4 system-simulator
13:27:29  18466  21.8 system-simulator
```

#### Running CPU usage script using 1000 clients for 1 minute

```console
TIMESTAMP  PID    %CPU    PROCESS
15:21:01  19186  41.5 system-simulator
15:21:13  19186  58.9 system-simulator
15:21:25  19186  41.9 system-simulator
15:21:37  19186  52.9 system-simulator
15:21:49  19186  62.1 system-simulator
```
</details>

## Solution

Initially, I believed the best way forward would be to modify the `request()` function to wait for the persistent store transaction to complete. I then realised that this modification would only make the system slower and the semaphore was regulating writes anyway.

I noticed a bottleneck was being created, due to the data processor semaphore permits not scaling with the amount of requests changed. I took the amount of permits that worked for a single client, and multiplied that by the number of clients.

```rust
sem: Arc::new(Semaphore::new(PERSIST_N)),
```
to

```rust
sem: Arc::new(Semaphore::new(PERSIST_N * N_CLIENTS)),
```

Results after semaphore optimisation:

### Summary of requests

There are no blocked requests under any amount of load any more.

The amount of requests does not plateau at a certain load, and they are proportional to the amount of clients being run. 

<details>

#### Running a single client:

```console
CPU     ID                    FUNCTION:NAME
  5   5281                        :tick-60s 

  non blocked requests                                             60
  persistent writes done                                           60
  persistent writes started                                        60
  requests done                                                    60
  requests started                                                 60
```

#### Under light load (15 clients):

```console
CPU     ID                    FUNCTION:NAME
  4   5281                        :tick-60s 

  non blocked requests                                            885
  persistent writes done                                          885
  persistent writes started                                       885
  requests done                                                   885
  requests started                                                885
```

#### Under medium load (125 clients):

```console
CPU     ID                    FUNCTION:NAME
  4   5281                        :tick-60s 

  non blocked requests                                           7375
  persistent writes done                                         7375
  persistent writes started                                      7375
  requests done                                                  7375
  requests started                                               7375
```

#### Under medium/high load (135 clients):

```console
CPU     ID                    FUNCTION:NAME
  6   5281                        :tick-60s 

  non blocked requests                                           7965
  persistent writes done                                         7965
  persistent writes started                                      7965
  requests done                                                  7965
  requests started                                               7965
```

#### Under high load (1000 clients):

```console
CPU     ID                    FUNCTION:NAME
  4   5281                        :tick-60s 

  persistent writes done                                        59000
  non blocked requests                                          59002
  persistent writes started                                     59002
  requests done                                                 59002
  requests started                                              59002
```

</details>

#### Request lifetime duration on a single thread

Variance has been reduced significantly. The trend is still to have the request lifetime reduced the higher the load. ~6541583ns average request lifetime when running a single client, ~2215251ns average request lifetime when running 135 clients, and ~852957ns when running 1000 clients (this last part is probably due to the random number generator).

<details>

#### Running a single client:

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                   59
  average request lifetime                                    6541583
  max request lifetime                                        8448000
  min request lifetime                                        4970334
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
         2097152 |                                         0        
         4194304 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  58       
         8388608 |@                                        1        
        16777216 |                                         0 
```

#### Under light load (15 clients):

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                   60
  average request lifetime                                    5591203
  max request lifetime                                        7801958
  min request lifetime                                        2574625
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
         1048576 |                                         0        
         2097152 |@@@                                      4        
         4194304 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@    56       
         8388608 |                                         0
```

#### Under medium load (125 clients):

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                   59
  average request lifetime                                    3666190
  max request lifetime                                        4411583
  min request lifetime                                         469375
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
          131072 |                                         0        
          262144 |@                                        1        
          524288 |                                         0        
         1048576 |                                         0        
         2097152 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@     53       
         4194304 |@@@                                      5        
         8388608 |                                         0 
```

#### Under medium/high load (135 clients):

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                  113
  average request lifetime                                    2215251
  max request lifetime                                        5576791
  min request lifetime                                          51250
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
           16384 |                                         0        
           32768 |@                                        2        
           65536 |                                         0        
          131072 |                                         1        
          262144 |@@                                       7        
          524288 |@@@@@@@@@@@@@@@@                         46       
         1048576 |                                         1        
         2097152 |@@@@@@@@@@@@@@@@@@@                      53       
         4194304 |@                                        3        
         8388608 |                                         0
```

#### Under high load (1000 clients):

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                  884
  average request lifetime                                     852957
  max request lifetime                                        8379833
  min request lifetime                                           7500
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
            2048 |                                         0        
            4096 |                                         1        
            8192 |                                         0        
           16384 |                                         0        
           32768 |                                         0        
           65536 |                                         0        
          131072 |                                         0        
          262144 |@@@@@@@@                                 176      
          524288 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@             618      
         1048576 |@@                                       36       
         2097152 |@                                        26       
         4194304 |@                                        27       
         8388608 |                                         0
```

</details>

#### Writing to persistent storage duration on a single OS thread

Since more threads are spawned due to the increase in the semaphore permits, each new thread processes less writes. This reduces variance in each thread.

<details>

#### Running a single client:

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                     59
  average write                                            1023451518
  max write                                                5112237834
  min write                                                  57745084
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
        16777216 |                                         0        
        33554432 |@@@@@@@@@                                14       
        67108864 |@@@@                                     6        
       134217728 |                                         0        
       268435456 |                                         0        
       536870912 |@@@@@@@@                                 12       
      1073741824 |@@@@@@@@@@@@@@@@                         24       
      2147483648 |@                                        2        
      4294967296 |@                                        1        
      8589934592 |                                         0
```

#### Under light load (15 clients):

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                    171
  average write                                             139800622
  max write                                                4105406000
  min write                                                  51638417
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
        16777216 |                                         0        
        33554432 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   164      
        67108864 |                                         0        
       134217728 |                                         0        
       268435456 |                                         0        
       536870912 |                                         1        
      1073741824 |@                                        4        
      2147483648 |                                         2        
      4294967296 |                                         0
```

#### Under medium load (125 clients):

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                    227
  average write                                              61112287
  max write                                                1076288000
  min write                                                  44318958
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
        16777216 |                                         0        
        33554432 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 225      
        67108864 |                                         0        
       134217728 |                                         0        
       268435456 |                                         0        
       536870912 |                                         1        
      1073741824 |                                         1        
      2147483648 |                                         0
```

#### Under medium/high load (135 clients):

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                    232
  average write                                              51078164
  max write                                                  62577042
  min write                                                  43816666
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
        16777216 |                                         0        
        33554432 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 232      
        67108864 |                                         0 
```

#### Under high load (1000 clients):

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                    293
  average write                                              16911109
  max write                                                2080384709
  min write                                                     46125
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
           16384 |                                         0        
           32768 |                                         2        
           65536 |                                         2        
          131072 |                                         1        
          262144 |                                         0        
          524288 |                                         1        
         1048576 |@@@                                      23       
         2097152 |@@@@@@@@                                 62       
         4194304 |@@@@@@@@@@@@@@                           100      
         8388608 |@@@@@@@                                  54       
        16777216 |@@@@@                                    33       
        33554432 |@@                                       14       
        67108864 |                                         0        
       134217728 |                                         0        
       268435456 |                                         0        
       536870912 |                                         0        
      1073741824 |                                         1        
      2147483648 |                                         0 
```
</details>

#### CPU usage

These percentages have been drastically reduced. At the highest load (1000 clients) we were previously at ~45% CPU usage. With the semaphore adjustment the percentage has been reduced to ~5% on average.

<details>

#### Running a single client:

```console
TIMESTAMP  PID    %CPU    PROCESS
18:06:14  22854   0.0 system-simulator
18:06:26  22854   0.0 system-simulator
18:06:38  22854   0.0 system-simulator
18:06:50  22854   0.0 system-simulator
18:07:02  22854   0.0 system-simulator
```

#### Under light load (15 clients):

```console
TIMESTAMP  PID    %CPU    PROCESS
18:10:27  22239   0.4  system-simulator
18:10:39  22239   0.8  system-simulator
18:10:51  22239   0.7  system-simulator
18:11:03  22239   0.0  system-simulator
18:11:15  22239   0.0  system-simulator
```

#### Under medium load (125 clients):

```console
TIMESTAMP  PID    %CPU    PROCESS
18:12:25  22319   1.1  system-simulator
18:12:37  22319   2.5  system-simulator
18:12:49  22319   4.5  system-simulator
18:13:01  22319   5.0  system-simulator
18:13:13  22319   0.0  system-simulator
```

#### Under medium/high load (135 clients):

```console
TIMESTAMP  PID    %CPU    PROCESS
18:14:00  22482   2.0  system-simulator
18:14:12  22482   3.7  system-simulator
18:14:24  22482   6.5  system-simulator
18:14:36  22482   0.2  system-simulator
18:14:48  22482   0.1  system-simulator
```

#### Under high load (1000 clients):

```console
TIMESTAMP  PID    %CPU    PROCESS
18:16:18  22645  10.9  system-simulator
18:16:30  22645   9.1  system-simulator
18:16:42  22645   7.7  system-simulator
18:16:54  22645   2.1  system-simulator
18:17:06  22645   4.0  system-simulator
```
</details>

## Reducing variance even further

Although the change in semaphore permits has drastically reduced variance in performance, one can go even further to reduce the current range of time it takes to store each of the elements. This can be done by implementing multipart uploads with a queue mechanism. (Implementing a queue mechanism and a multipart upload functionality would take a significant amount of time. I believe this falls out of the scope of the exercise?)

The current range for network delay is quite narrow, so for this system I don't think it's necessary to make any network changes.

## Update 29/June/2021

There are several inconsistencies between the data collected with the DTrace scripts and the expected result.

The total request lifetime readings are incorrect. There are several outliers and inconsistent data.

Why are the persistent store latency readings decreasing with more clients? This doesn't make much sense and should not be happening.

### Approaches I tried
- Decrease the range between in latency of the random number generator for the persistent store made no difference in readings for request lifetimes or persistent store.
- Setting the sleep time in the persistent store thread as a defined number (`50_000` microseconds) instead of a randomly generated one, still resulted in varying latency (i.e. no change):

    ```console
    Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
      total writes                                                   1976
      average write                                              65804674
      max write                                               17229761375
      min write                                                     24792
      visualisation of writes                           
               value  ------------- Distribution ------------- count    
                8192 |                                         0        
               16384 |                                         4        
               32768 |                                         7        
               65536 |                                         2        
              131072 |                                         5        
              262144 |                                         0        
              524288 |                                         2        
             1048576 |                                         8        
             2097152 |                                         0        
             4194304 |                                         0        
             8388608 |                                         0        
            16777216 |                                         0        
            33554432 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@   1878     
            67108864 |@                                        39       
           134217728 |                                         22       
           268435456 |                                         7        
           536870912 |                                         0        
          1073741824 |                                         0        
          2147483648 |                                         1        
          4294967296 |                                         0        
          8589934592 |                                         0        
         17179869184 |                                         1        
         34359738368 |                                         0 
    ```

- I created a [flowchart](./scripts/diagram-req.sh) to follow the thread beginning with request-start and it does not recognise persist-done. I was under the impression this should show children threads? Is this is because it's in green threads instead of OS threads?

    ```console
    CPU FUNCTION                                 
      5 | _ZN16system_simulator7persist7Persist7enqueue17h319475d7781f757dE:persist-start           3918458
      5 | _ZN16system_simulator7persist7Persist7enqueue17h319475d7781f757dE:persist-start           3946458
      5 | _ZN16system_simulator7persist7Persist7enqueue17h319475d7781f757dE:persist-start           3952083
      5 | _ZN16system_simulator7persist7Persist7enqueue17h319475d7781f757dE:persist-start           3957375
      5 | _ZN16system_simulator7persist7Persist7enqueue17h319475d7781f757dE:persist-start           3962208
      5 | _ZN16system_simulator7persist7Persist7enqueue17h319475d7781f757dE:persist-start           3969958
      5 | _ZN16system_simulator7persist7Persist7enqueue17h319475d7781f757dE:persist-start           3974666
      5 | _ZN16system_simulator7persist7Persist7enqueue17h319475d7781f757dE:persist-start           3979541
      5 | _ZN16system_simulator6client6Client2go28_$u7b$$u7b$closure$u7d$$u7d$17hacec9e85df845263E:request-done           6600791
    ```

- I created a [flowchart](./scripts/persist-thread-diagram-req.sh) inside the tokio task for persistent store. The times are _somewhat_ consistent, if I put the sleep duration to a set number and set the sleep time to `50_000` microseconds.

    ```console
    CPU FUNCTION                                 
    <...>
    0 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          51556125
    2 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          51027833
    1 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done         159038209
    3 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          56293750
    3 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          55701250
    1 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          53783458
    3 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          54327709
    2 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          54395750
    0 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          52258416
    3 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          51845375
    2 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done             25917
    <...>
    ```

### Conclusions so far

I'm guessing total request lifetime records are wrong because my scripts ignore the `persist-done` probe, which means they are not taking into account the green threads. How does one go on about following child green threads in DTrace?

Once I have an answer to the above, I will have more of an idea on how to fix the persistent store script.

## Update 3/Jul/2021

After talking with Adam, I learned that due to the way DTrace and green threads work together, the correct way to capture information about concurrent code that uses green threads is to follow the ID that correlates probes rather than the thread ID.

I made the following changes to the DTrace scripts:

```shell
self->follow
```

to

```shell
follow[arg0]
```

The collected data makes sense now as shown below. All of these readings have been taken when the system is still blocking requests.

#### Request lifetime duration

As you can see, the total requests now matches the [information collected](#summary-of-requests) when using the [request count](./scripts/count.sh) script.

<details>

#### Running a single client:

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                   60
  average request lifetime                                    6763041
  max request lifetime                                        8521459
  min request lifetime                                        5262250
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
         2097152 |                                         0        
         4194304 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@  59       
         8388608 |@                                        1        
        16777216 |                                         0        
```

#### Under light load (15 clients):

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                  885
  average request lifetime                                    7231868
  max request lifetime                                       19259875
  min request lifetime                                        4159333
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
         1048576 |                                         0        
         2097152 |                                         2        
         4194304 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         712      
         8388608 |@@@@@@@@                                 168      
        16777216 |                                         3        
        33554432 |                                         0 
```

#### Under medium load (125 clients):

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                 7418
  average request lifetime                                    8761273
  max request lifetime                                       37544667
  min request lifetime                                        3539958
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
         1048576 |                                         0        
         2097152 |                                         9        
         4194304 |@@@@@@@@@@@@@@@@@@@@@@@@@@               4896     
         8388608 |@@@@@@@@@@@                              2085     
        16777216 |@@                                       426      
        33554432 |                                         2        
        67108864 |                                         0
```

#### Under medium/high load (135 clients):

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                 7419
  average request lifetime                                    8595895
  max request lifetime                                       35859583
  min request lifetime                                        3717500
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
         1048576 |                                         0        
         2097152 |                                         3        
         4194304 |@@@@@@@@@@@@@@@@@@@@@@@@@@@              4965     
         8388608 |@@@@@@@@@@@                              2085     
        16777216 |@@                                       365      
        33554432 |                                         1        
        67108864 |                                         0 
```

#### Under high load (1000 clients):

```console
Summary of all request lifetimes taken in one minute represented in nanoseconds:
  total requests                                                 6807
  average request lifetime                                 6813586360
  max request lifetime                                     6895553917
  min request lifetime                                     6746383958
  request lifetimes visualisation                   
           value  ------------- Distribution ------------- count    
      2147483648 |                                         0        
      4294967296 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 6807     
      8589934592 |                                         0 
```

</details>

#### Writing to persistent storage duration

Given the new approach to correlate probes, the `persist-async-start` probe is no longer necessary. The `persist-start` probe can be used instead.

<details>

#### Running a single client:

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                     60
  average write                                              64737102
  max write                                                  78047417
  min write                                                  52074250
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
        16777216 |                                         0        
        33554432 |@@@@@@@@@@@@@@@@@@@@@@@@@@@              40       
        67108864 |@@@@@@@@@@@@@                            20       
       134217728 |                                         0   
```

#### Under light load (15 clients):

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                    885
  average write                                              61787007
  max write                                                  81290167
  min write                                                  51105667
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
        16777216 |                                         0        
        33554432 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      773      
        67108864 |@@@@@                                    112      
       134217728 |                                         0 
```

#### Under medium load (125 clients):

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                   7413
  average write                                              61725998
  max write                                                  79233667
  min write                                                  50252000
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
        16777216 |                                         0        
        33554432 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       6354     
        67108864 |@@@@@@                                   1059     
       134217728 |                                         0 
```

#### Under medium/high load (135 clients):

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                   7415
  average write                                              61674627
  max write                                                  80700583
  min write                                                  50174500
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
        16777216 |                                         0        
        33554432 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@       6374     
        67108864 |@@@@@@                                   1041     
       134217728 |                                         0
```

#### Under high load (1000 clients):

```console
Summary of all writes to persistent storage taken in one minute represented in nanoseconds:
  total writes                                                   7649
  average write                                              61687820
  max write                                                  92532375
  min write                                                  50188375
  visualisation of writes                           
           value  ------------- Distribution ------------- count    
        16777216 |                                         0        
        33554432 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@      6610     
        67108864 |@@@@@                                    1039     
       134217728 |                                         0  
```
</details>

Success!

## Update 11/Jul/2021

Moar histograms!

There seem to be a few "outliers", but in this case I do believe it is because of the random number generators? Happy to be proven wrong though :D

#### Request lifetime duration

In the previous examples most requests fell into one or two buckets of time values. To go further with granularity and get a clearer picture, `lquantize` can be used instead of `quantize`.

This information was collected using the [linear quantize](./scripts/linear-q-request-lifetime.sh) script for request lifetimes.

<details>

#### Running a single client:

```console
  Request lifetimes over time in microseconds       
           value  ------------- Distribution ------------- count    
               0 |                                         0        
              50 |@                                        2        
             100 |@@@@@@@@@@@@@@@@@@                       26       
             150 |@@@@@@@@@@@@@@@                          22       
             200 |@                                        2        
             250 |                                         0        
             300 |                                         0        
             350 |                                         0        
             400 |                                         0        
             450 |@@@                                      5        
             500 |@                                        2        
             550 |                                         0 
```

#### Under light load (15 clients):

```console
  Request lifetimes over time in microseconds       
           value  ------------- Distribution ------------- count    
               0 |                                         0        
             100 |                                         3        
             200 |@                                        12       
             300 |@                                        29       
             400 |@@@@                                     97       
             500 |@@@                                      68       
             600 |@@@                                      73       
             700 |@@@@                                     82       
             800 |@@@@@@@@@@@@@@                           302      
             900 |@@@@@@                                   122      
            1000 |@@                                       48       
            1100 |@                                        21       
            1200 |@                                        17       
            1300 |                                         7        
            1400 |                                         4        
            1500 |                                         0
```

#### Under medium load (125 clients):

```console
  Request lifetimes over time in microseconds       
           value  ------------- Distribution ------------- count    
             < 0 |                                         0        
               0 |@@@                                      547      
             500 |@@@@@@@@@@@@@@@@@@                       3296     
            1000 |@@@@@@@@@@@                              2006     
            1500 |@@@@@                                    926      
            2000 |@@                                       429      
            2500 |@                                        160      
            3000 |                                         45       
            3500 |                                         14       
            4000 |                                         2        
            4500 |                                         0
```

#### Under medium/high load (135 clients):

```console
  Request lifetimes over time in microseconds       
           value  ------------- Distribution ------------- count    
             < 0 |                                         0        
               0 |                                         1        
            1000 |                                         14       
            2000 |                                         48       
            3000 |@                                        113      
            4000 |@@                                       386      
            5000 |@@@@@                                    1017     
            6000 |@@@@@@@@                                 1520     
            7000 |@@@@@@@@                                 1518     
            8000 |@@@@@@@                                  1353     
            9000 |@@@@@                                    888      
           10000 |@@@                                      484      
           11000 |@                                        214      
           12000 |@                                        108      
           13000 |                                         44       
           14000 |                                         16       
           15000 |                                         2        
           16000 |                                         0 
```

#### Under high load (1000 clients):

```console
  Request lifetimes over time in microseconds       
           value  ------------- Distribution ------------- count    
         2950000 |                                         0        
         3000000 |@                                        120      
         3050000 |@@                                       294      
         3100000 |@@@@                                     731      
         3150000 |@@@@@@@@@@@@                             1966     
         3200000 |@@                                       330      
         3250000 |@@@@                                     666      
         3300000 |@                                        140      
         3350000 |@@@@                                     638      
         3400000 |@@@@@@@@                                 1400     
         3450000 |@@@                                      534      
         3500000 |                                         0
```

</details>

#### Blocked vs non blocked requests

The following histograms show the differences in times for blocked and non-blocked requests under different amount of load.

This information was collected using the [blocked](./scripts/linear-q-blocked.sh) and [non-blocked](./scripts/linear-q-non-blocked.sh) linear quantize scripts for request lifetimes.

I was only able to collect the data from the time the `isim*:::request-nonblock` and `isim*:::request-block` probes were fired. My initial intention was to take the entire request time and then filter out by blocked and non-blocked, but was unable to do so 🤔. I'll keep thinking about this one.

<details>

#### Running a single client:

```console
  Request lifetimes for non blocked requests from the time they are queued in microseconds
           value  ------------- Distribution ------------- count    
             < 0 |                                         0        
               0 |@                                        1        
              50 |@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@         47       
             100 |@@@@@                                    7        
             150 |                                         0        
             200 |@                                        1        
             250 |@                                        1        
             300 |                                         0        
             350 |                                         0        
             400 |@                                        2        
             450 |                                         0 
```

#### Under light load (15 clients):

```console
  Request lifetimes for non blocked requests from the time they are queued in microseconds
           value  ------------- Distribution ------------- count    
             < 0 |                                         0        
               0 |@                                        24       
             100 |@@@@@@@@@@@                              196      
             200 |@@@@@@@@@@@@@@                           257      
             300 |@@@@@@                                   110      
             400 |@                                        15       
             500 |@@                                       43       
             600 |@@@@                                     65       
             700 |@                                        13       
             800 |                                         1        
             900 |                                         0 

  Request lifetimes for blocked requests from the time they are blocked in microseconds
           value  ------------- Distribution ------------- count    
               0 |                                         0        
             100 |@@                                       12       
             200 |@@@@                                     23       
             300 |@@@@@                                    29       
             400 |@@@@                                     24       
             500 |@@@@@                                    28       
             600 |@@@@@                                    27       
             700 |@@@@                                     20       
             800 |@@                                       13       
             900 |@@                                       13       
            1000 |@@                                       11       
            1100 |@@                                       9        
            1200 |@                                        5        
            1300 |                                         0 
```

#### Under medium load (125 clients):

```console
  Request lifetimes for non blocked requests from the time they are queued in microseconds
           value  ------------- Distribution ------------- count    
             < 0 |                                         0        
               0 |                                         2        
             100 |                                         26       
             200 |@@@                                      315      
             300 |@@@                                      344      
             400 |@@@@@@@@@@@@@@@@@@@                      2176     
             500 |@@@                                      393      
             600 |@                                        103      
             700 |@                                        132      
             800 |@@@@@@                                   739      
             900 |@                                        156      
            1000 |                                         5        
            1100 |                                         47       
            1200 |@                                        101      
            1300 |                                         9        
            1400 |                                         1        
            1500 |                                         4        
            1600 |                                         0

  Request lifetimes for blocked requests from the time they are blocked in microseconds
           value  ------------- Distribution ------------- count    
               0 |                                         0        
             200 |                                         6        
             400 |                                         15       
             600 |                                         20       
             800 |@@@@@@@@@@@@                             796      
            1000 |@                                        61       
            1200 |@@@@@@@@@@@                              791      
            1400 |@                                        71       
            1600 |@@@@@@@                                  497      
            1800 |@                                        66       
            2000 |@@@@                                     255      
            2200 |                                         32       
            2400 |@                                        86       
            2600 |                                         22       
            2800 |                                         23       
            3000 |                                         10       
            3200 |                                         7        
            3400 |                                         1        
            3600 |                                         1        
            3800 |                                         0
```

#### Under medium/high load (135 clients):

```console
  Request lifetimes for non blocked requests from the time they are queued in microseconds
           value  ------------- Distribution ------------- count    
             300 |                                         0        
             400 |@@@@@@@@@@@@@@@@@@@@                     1        
             500 |                                         0        
             600 |                                         0        
             700 |                                         0        
             800 |                                         0        
             900 |@@@@@@@@@@@@@@@@@@@@                     1        
            1000 |                                         0 

  Request lifetimes for blocked requests from the time they are blocked in microseconds
           value  ------------- Distribution ------------- count    
             < 0 |                                         0        
               0 |                                         2        
            1000 |                                         55       
            2000 |@                                        229      
            3000 |@@                                       459      
            4000 |@@@@@                                    954      
            5000 |@@@@@@@@                                 1464     
            6000 |@@@@@@@@                                 1616     
            7000 |@@@@@@@                                  1272     
            8000 |@@@@                                     847      
            9000 |@@                                       477      
           10000 |@                                        235      
           11000 |                                         75       
           12000 |                                         25       
           13000 |                                         8        
           14000 |                                         1        
           15000 |                                         0
```

#### Under high load (1000 clients):

```console
  Request lifetimes for blocked requests from the time they are blocked in microseconds
           value  ------------- Distribution ------------- count    
         2750000 |                                         0        
         2800000 |                                         12       
         2850000 |@                                        176      
         2900000 |@                                        213      
         2950000 |@                                        215      
         3000000 |@                                        110      
         3050000 |                                         78       
         3100000 |@@@                                      559      
         3150000 |@@@@                                     626      
         3200000 |@@@@@@                                   1044     
         3250000 |@@@@@@@@                                 1406     
         3300000 |@@@                                      491      
         3350000 |@@@@@                                    806      
         3400000 |@@@                                      582      
         3450000 |@@@                                      502      
         3500000 |                                         0 
```
</details>