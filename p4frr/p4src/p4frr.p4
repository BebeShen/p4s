/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

#include "include/headers.p4"
#include "include/ingress.p4"
#include "include/egress.p4"

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
