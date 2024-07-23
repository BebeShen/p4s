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