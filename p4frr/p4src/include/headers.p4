#ifndef _HEADERS_P4_
#define _HEADERS_P4_
#endif

/* -*- Constants and Types -*- */

#ifndef IPV4_HOST_SIZE
#define IPV4_HOST_SIZE 65536
#endif

#ifndef IPV4_LPM_SIZE
#define IPV4_LPM_SIZE 12288
#endif

// # of path up to 2^10
#ifndef PRIMARY_PATH_SIZE
#define PRIMARY_PATH_SIZE 1024
#endif

// 2^(PortId_t)
#ifndef PORT_STATUS_SIZE
#define PORT_STATUS_SIZE 512
#endif

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> ether_type_t;
typedef bit<1> status_t;

const bit<16> ETHERTYPE_VLAN = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<16> ETHERTYPE_IPV6 = 0x86DD;

const PortId_t CPU_PORT = 64;

const int IPV4_HOST_TABLE_SIZE = IPV4_HOST_SIZE;
const int IPV4_LPM_TABLE_SIZE  = IPV4_LPM_SIZE;
const int PRIMARY_PATH_TABLE_SIZE = PRIMARY_PATH_SIZE;

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
    bit<32> dst_addr;
    bit<1> table_hit;
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
    bit<32> dst_addr;
    bit<1> table_hit;
}

/* Global Egress Header */
struct my_egress_headers_t {
}

/* Global Egress metadata */
struct my_egress_metadata_t {
}