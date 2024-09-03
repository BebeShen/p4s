# HDP in SDN

Implement "Fast Failover with Hierarchical Disjoint Paths in SDN"

## Architecture

### Data Plane

I remove `flow` identifier from FFRMT program and properly configure table entries to simulate the behavior of HDP.

e.g. `Flow table`, `Group table` -> Port candi table with setting up `cur` for all port.

### Control Plane

## Compile & Build

```shell
# using tool script provided by intel
$ ~/tools/p4_build.sh ~/p4code/{{ program dir }}/p4src/{{ program main file name }}.p4 

# OR using cmake under program dir
# [NOTE]: need absolute path
$ cmake $SDE/p4studio/ -DCMAKE_INSTALL_PREFIX=$SDE_INSTALL -DCMAKE_MODULE_PATH=$SDE/cmake -DP4_NAME=p4frr -DP4_PATH=/root/p4code/{{ program dir }}/p4src/{{ program main file name }}.p4 
$ make && make install

# OR using bf-p4c (howard recommend)
$ bf-p4c     --arch tna --create-graphs --p4runtime-files p4c-out/p4info.txt --verbose 2     --p4runtime-force-std-externs -o p4c-out -D CPU_PORT=192 {P4 program}
```

> The compilation will get **ERROR** if the p4 program have syntax error when using tool script `p4_build.sh`.
> So, if you want to see the compile error message, I suggest you use cmake
