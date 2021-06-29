# Troubleshooting the troubleshooting data

There are several inconsistencies between the data collected with the DTrace scripts and the expected result.

The total request lifetime readings are incorrect. There are several outliers and inconsistent data.

Why are the persistent store latency readings decreasing with more clients? This doesn't make much sense and should not be happening.

## Approaches I tried
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
      4 |   4 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          53795125
  6 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          53929167
  7 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          53841167
  4 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          51441458
  5 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          51324708
  7 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          51356666
  3 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          51587500
  2 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          51823750
  1 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          50927250
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
  1 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          50775334
  3 | _ZN16system_simulator7persist7Persist7enqueue28_$u7b$$u7b$closure$u7d$$u7d$17hbdc2fccf7323be45E:persist-done          48741667
  <...>
    ```

## Conclusions so far

I'm guessing total request lifetime records are wrong because my scripts ignore the `persist-done` probe, which means they are not taking into account the green threads. How does one go on about following child green threads in DTrace?

Once I have an answer to the above, I will have more of an idea on how to fix the persistent store script.
