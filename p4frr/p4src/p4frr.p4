/* -*- P4_16 -*- */

#include <core.p4>
#include <tna.p4>

#ifndef _HEADERS_P4_
#define _HEADERS_P4_

/* -*- Constants and Types -*- */

#ifndef IPV4_HOST_SIZE
#define IPV4_HOST_SIZE 65536
#endif

#ifndef IPV4_LPM_SIZE
#define IPV4_LPM_SIZE 12288
#endif

// # of path up to 2^10(1024)
#ifndef PATH_INDEX_SIZE
#define PATH_INDEX_SIZE 10
#endif

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> ether_type_t;

const bit<16> ETHERTYPE_VLAN = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<16> ETHERTYPE_IPV6 = 0x86DD;
const bit<32> PATH_INDEX_REG_SIZE  = PATH_INDEX_SIZE;

const PortId_t CPU_PORT = 64;

const int IPV4_HOST_TABLE_SIZE = IPV4_HOST_SIZE;
const int IPV4_LPM_TABLE_SIZE  = IPV4_LPM_SIZE;

/* -*- Headers -*- */

header ethernet_h {
    mac_addr_t   dst_addr;
    mac_addr_t   src_addr;
    ether_type_t ether_type;
}

header vlan_h {
    bit<3> pcp;
    bit<1> dei;
    bit<12> vid;
    bit<16> ether_type;
}

header ipv4_h {
    bit<4>       version;
    bit<4>       ihl;
    bit<8>       diffserv;
    bit<16>      total_len;
    bit<16>      identification;
    bit<3>       flags;
    bit<13>      frag_offset;
    bit<8>       ttl;
    bit<8>       protocol;
    bit<16>      hdr_checksum;
    ipv4_addr_t  src_addr;
    ipv4_addr_t  dst_addr;
}


/* -*- Struct -*- */

/*  */
struct digest_message_t {
    bit<48> ingress_tstamp;
    bit<32> src_addr;
}

/* Global Ingress Header */
struct my_ingress_headers_t {
    ethernet_h   ethernet;
    vlan_h       vlan;
    ipv4_h       ipv4;
}

/* Global Ingress metadata */
struct my_ingress_metadata_t {
    bit<48> ingress_tstamp;
    bit<32> src_addr;
}

/* Global Egress Header */
struct my_egress_headers_t {
}

/* Global Egress metadata */
struct my_egress_metadata_t {
}

/* -*- Ingress Processing -*- */

/* Ingress Parser */
parser IngressParser(packet_in        pkt,
    /* User */
    out my_ingress_headers_t          hdr,
    out my_ingress_metadata_t         meta,
    /* Intrinsic */
    out ingress_intrinsic_metadata_t  ig_intr_md)
{
    state start {
        /* Mandatory code required by Tofino Architecture */
        pkt.extract(ig_intr_md);
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }

    /* Parse Ethernet */
    state parse_ethernet {
        pkt.extract(hdr.ethernet);
        transition select(hdr.ethernet.ether_type) {
            ETHERTYPE_VLAN:     parse_vlan;
            ETHERTYPE_IPV4:     parse_ipv4;
            default:            accept;
        }
    }

    /* Parse VLAN */
    state parse_vlan {
        pkt.extract(hdr.vlan);
        transition select(hdr.vlan.ether_type) {
            ETHERTYPE_IPV4:     parse_ipv4;
            default:            accept;
        }
    }
    
    /* Parse IPv4 */
    state parse_ipv4 {
        pkt.extract(hdr.ipv4);
        transition accept;
    }
}

/* Ingress Control */
control Ingress(
    /* User */
    inout my_ingress_headers_t                       hdr,
    inout my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_t               ig_intr_md,
    in    ingress_intrinsic_metadata_from_parser_t   ig_prsr_md,
    inout ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md,
    inout ingress_intrinsic_metadata_for_tm_t        ig_tm_md)
{
    /* Stateful Objects section */
    Register<bit<32>, _>() fork_switch_reg;
    RegisterAction<bit<32>, _, bit<32>> (fork_switch_reg) read_fork_switch_reg {
        void apply(inout bit<32> value, out bit<32> read_value){
            read_value = value;
        }
    }
    RegisterAction<bit<32>, _, void> (fork_switch_reg) write_fork_switch_reg {
        void apply(inout bit<32> value, out bit<32> result_value){
            value = hdr.ipv4.src_addr;
            result_value = value;
        }
    }

    /* Action section */
    action set_digest(){
        ig_dprsr_md.digest_type = 1;
    }
    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }

    action lookup_forwarding() {

    }

    /* Table section */
    table ipv4_host {
        key = { hdr.ipv4.dst_addr : exact; }
        actions = {
            send; drop;
        }
        size = IPV4_HOST_TABLE_SIZE;
    }

    table ipv4_lpm {
        key     = { hdr.ipv4.dst_addr : lpm; }
        actions = { send; drop; }

        default_action = send(CPU_PORT);
        size           = IPV4_LPM_TABLE_SIZE;
    }

    table path {
        key = {  }
    }

    table forwarding {
        key = {  }
    }

    /* Main Ingress Logic */
    apply {
        bit<32> test_rv = write_fork_switch_reg.execute(0);
        meta.ingress_tstamp = ig_intr_md.ingress_mac_tstamp;
        meta.src_addr = test_rv;
        set_digest();
        if (hdr.ipv4.isValid()) {
            if (ipv4_host.apply().miss) {
                ipv4_lpm.apply();
            }
        }
    }
}

/* Ingress De-Parser */
control IngressDeparser(packet_out pkt,
    /* User */
    inout my_ingress_headers_t                       hdr,
    in    my_ingress_metadata_t                      meta,
    /* Intrinsic */
    in    ingress_intrinsic_metadata_for_deparser_t  ig_dprsr_md)
{
    Digest<digest_message_t>() idigest;

    action debug_digest() {
        idigest.pack({
            meta.ingress_tstamp,

        })
    }
    // Output valid headers in the correct order
    apply {
        pkt.emit(hdr);
    }
}


/* -*- Egress Processing -*- */

/* Egress Parser */
parser EgressParser(packet_in        pkt,
    /* User */
    out my_egress_headers_t          hdr,
    out my_egress_metadata_t         meta,
    /* Intrinsic */
    out egress_intrinsic_metadata_t  eg_intr_md)
{
    state start {
        pkt.extract(eg_intr_md);
        transition accept;
    }
}


/* Egress Control */
control Egress(
    /* User */
    inout my_egress_headers_t                          hdr,
    inout my_egress_metadata_t                         meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_t                  eg_intr_md,
    in    egress_intrinsic_metadata_from_parser_t      eg_prsr_md,
    inout egress_intrinsic_metadata_for_deparser_t     eg_dprsr_md,
    inout egress_intrinsic_metadata_for_output_port_t  eg_oport_md)
{
    apply {
    }
}

/* Egress De-Parser */
control EgressDeparser(packet_out pkt,
    /* User */
    inout my_egress_headers_t                       hdr,
    in    my_egress_metadata_t                      meta,
    /* Intrinsic */
    in    egress_intrinsic_metadata_for_deparser_t  eg_dprsr_md)
{
    apply {
        pkt.emit(hdr);
    }
}

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
