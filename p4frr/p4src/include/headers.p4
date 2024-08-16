#ifndef _HEADERS_P4_
#define _HEADERS_P4_
#endif

/* -*- Constants and Types -*- */

#ifndef FLOW_WIDTH
#define FLOW_WIDTH 10
#endif

// max # of flow : 32
#ifndef FLOW_SIZE
// #define FLOW_SIZE 1 << FLOW_WIDTH
#define FLOW_SIZE 32
#endif

// Port number range in 0 ~ 256
#ifndef PORT_SIZE
// #define PORT_SIZE 1 << PORT_ID_WIDTH
#define PORT_SIZE 256
#endif

// #(flow)*#(max num of port candi) = 32*8
#ifndef PORT_CANDI_SIZE
#define PORT_CANDI_SIZE 256
#endif

typedef bit<48> mac_addr_t;
typedef bit<32> ipv4_addr_t;
typedef bit<16> ether_type_t;
typedef bit<1>  status_t;
typedef bit<FLOW_WIDTH> flow_index_t;
typedef bit<PORT_ID_WIDTH>  ig_port_t;
typedef bit<PORT_ID_WIDTH>  cur_number_t;

const bit<16> ETHERTYPE_VLAN = 0x8100;
const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<16> ETHERTYPE_IPV6 = 0x86DD;
const bit<7>  RECIRCU_PORT   = 7w68;
const bit<16> IG_PORT_INIT = 16w511;

// const PortId_t CPU_PORT = 64;

enum bit<1> PortStatus_t {
    UP      = 1w1,
    DOWN    = 1w0
}
enum bit<1> TableHitMiss_t {
    HIT     = 1w1,
    MISS    = 1w0
}

/* Table Sizing */
const int ADDR_2_FLOW_TABLE_SIZE = FLOW_SIZE;
const int PORT_CANDI_TALBE_SIZE = PORT_CANDI_SIZE;
const int PORT_STATUS_TALBE_SIZE = PORT_SIZE;

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
    // bit<48> ingress_tstamp;
    bit<32> src_addr;
    bit<32> dst_addr;
    status_t p_st;
    PortId_t fin_port;
    PortId_t in_port;
    PortId_t out_port;
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
    // bit<48> ingress_tstamp;
    // bit<32> src_addr;
    // bit<32> dst_addr;
    status_t p_st;
    PortId_t fin_port;
    PortId_t in_port;
    PortId_t out_port;
    bit<1> table_hit;
}

/* Global Egress Header */
struct my_egress_headers_t {
}

/* Global Egress metadata */
struct my_egress_metadata_t {
}