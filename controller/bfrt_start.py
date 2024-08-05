#!/usr/bin/python3

from __future__ import print_function

import os
import sys
import pdb

SDE_INSTALL   = os.environ['SDE_INSTALL']
SDE_PYTHON2   = os.path.join(SDE_INSTALL, 'lib', 'python2.7', 'site-packages')
sys.path.append(SDE_PYTHON2)
sys.path.append(os.path.join(SDE_PYTHON2, 'tofino'))

PYTHON3_VER   = '{}.{}'.format(
                    sys.version_info.major,
                    sys.version_info.minor)
SDE_PYTHON3   = os.path.join(SDE_INSTALL, 'lib', 'python' + PYTHON3_VER, 'site-packages')
sys.path.append(SDE_PYTHON3)
sys.path.append(os.path.join(SDE_PYTHON3, 'tofino'))
sys.path.append(os.path.join(SDE_PYTHON3, 'tofino', 'bfrt_grpc'))

import grpc
import bfrt_grpc.bfruntime_pb2 as bfruntime_pb2
import bfrt_grpc.client as bfrt_client

#
# Connect to the BF Runtime Server
#
interface = bfrt_client.ClientInterface(
    grpc_addr = 'localhost:50052',
    client_id = 0,
    device_id = 0)
print('Connected to BF Runtime Server')

#
# Get the information about the running program
#
bfrt_info = interface.bfrt_info_get()
print('The target runs the program ', bfrt_info.p4_name_get())

#
# Establish that you are using this program on the given connection
#
interface.bind_pipeline_config(bfrt_info.p4_name_get())

################### You can now use BFRT CLIENT ###########################

#
#   This equal to "bfrt> bfrt.{program}.pipe.info" in Interactive bfrt_python
#

from tabulate import tabulate

dev_tgt = bfrt_client.Target(0)

data = []

for name in bfrt_info.table_dict.keys():
    if name.split('.')[0] == 'pipe':
        t = bfrt_info.table_get(name)
        name = t.info.name_get()
        type = t.info.type_get()
        size = t.info.size_get()

        try:
            result = t.usage_get(dev_tgt)
            usage = next(result)
        except:
            usage = 'n/a'
        data.append([name, type, size, usage])

print(tabulate(data, headers=['Full Table Name', 'Type', 'Usage', 'Capacity']))

############################## FINALLY ####################################
#
# If you use SDE prior to 9.4.0, uncomment the line below
# interface._tear_down_stream()

print("The End")
