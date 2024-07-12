#ifndef _HEADERS_P4_
#define _HEADERS_P4_

/* -*- Constants and Types -*- */

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> ether_type_t;

const bit<16> ETHERTYPE_VLAN = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<16> ETHERTYPE_IPV6 = 0x86DD;

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

/* Global Ingress Header */
struct my_ingress_headers_t {
    ethernet_h   ethernet;
    vlan_h       vlan;
    ipv4_h       ipv4;
}

/* Global Ingress metadata */
struct my_ingress_metadata_t {
}

/* Global Egress Header */
struct my_egress_headers_t {
}

/* Global Egress metadata */
struct my_egress_metadata_t {
}