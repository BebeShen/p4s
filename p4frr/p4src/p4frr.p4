/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

#include "include/headers.p4"
#include "include/ingress.p4"
#include "include/egress.p4"

/* Constants and Types */

const PortId_t CPU_PORT = 64;

#ifndef IPV4_HOST_SIZE
#define IPV4_HOST_SIZE 65536
#endif

#ifndef IPV4_LPM_SIZE
#define IPV4_LPM_SIZE 12288
#endif

const int IPV4_HOST_TABLE_SIZE = IPV4_HOST_SIZE;
const int IPV4_LPM_TABLE_SIZE  = IPV4_LPM_SIZE;

/* Program Pipeline Definitions */

Pipeline(
    IngressParser(),
    Ingress(),
    IngressDeparser(),
    EgressParser(),
    Egress(),
    EgressDeparser()
) pipe;

/* Top-Level Pipes Instance */

Switch(pipe) main;
