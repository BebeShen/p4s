# Some Note

- P4 doesn't have array, loop, 
- P4 Pipeline defined by program will be duplicated in every pipe of P4 target.
  - There are no tables or extern objects physically shared across seperate pipes.
- Port metadata can't contain no more than `64 bits` (`8 bytes`).
- Tofino mainatain full packet throughput when using Bridge Header with its size at most `28` bytes.
- Register always Asymmetric.
- Control Plane API return the shadow of HW
  - If one want to get real extern object data, need add `from_hw=True` in arguments when call API.
- Tofino can only resubmit each packet once.
  - if one perform resubmit on a packet with `resubmit_flag == 1`, the packet will be dropped.
