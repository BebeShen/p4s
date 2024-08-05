# P4 Fast Failure Recovery Mechanism

Implement Fast Failure Recovery Mechanism by using Tofino-based P4 Programmable Hardware

## Architecture

### Data Plane

### Control Plane

## Compile & Build

```shell
# using tool script provided by intel
$ ~/tools/p4_build.sh ~/p4code/{{ program dir }}/p4src/{{ program main file name }}.p4 

# OR using cmake under program dir
# [NOTE]: need absolute path
$ cmake $SDE/p4studio/ -DCMAKE_INSTALL_PREFIX=$SDE_INSTALL -DCMAKE_MODULE_PATH=$SDE/cmake -DP4_NAME=p4frr -DP4_PATH=/root/p4code/{{ program dir }}/p4src/{{ program main file name }}.p4 
$ make && make install
```

> The compilation will get **ERROR** if the p4 program have syntax error when using tool script `p4_build.sh`.
> So, if you want to see the compile error message, I suggest you use cmake
