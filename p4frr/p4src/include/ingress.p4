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
    Register<status_t, PortId_t>(PORT_STATUS_SIZE) port_status_register;
    RegisterAction<status_t, PortId_t, status_t> (port_status_register) read_port_status = {
        void apply(inout status_t register_data, out status_t read_value){
            read_value = register_data;
        }
    };

    /* Action section */
    action write_to_register() {
        port_status_register.write(1, hdr.ipv4.src_addr);
    }
    action set_digest(){
        ig_dprsr_md.digest_type = 1;
    }
    action primary_path_table_hit(){
        set_digest();
        meta.table_hit = 1;
    }
    action primary_path_table_miss(){
        set_digest();
        meta.table_hit = 0;
    }
    action send(PortId_t port) {
        ig_tm_md.ucast_egress_port = port;
    }
    action bounce_back() {
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        ig_tm_md.bypass_egress = 1;
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
        actions = { 
            send; drop; 
        }

        default_action = send(CPU_PORT);
        size           = IPV4_LPM_TABLE_SIZE;
    }

    table primary_path {
        key = { 
            hdr.ipv4.src_addr   :   exact;
            hdr.ipv4.dst_addr   :   exact;    
        }
        actions = {
            send; drop;
        }
        
        size           = PRIMARY_PATH_TABLE_SIZE;
    }

    /* Main Ingress Logic */
    apply {
        if (hdr.ipv4.isValid()) {

            bit<1> port_status;
            /* Get Ingress Timestamp */
            meta.ingress_tstamp = ig_intr_md.ingress_mac_tstamp;
            
            if (primary_path.apply().miss) {
                /* No rule for primary path (Control Plane not install rule YET) */
                meta.src_addr = 2;
                meta.dst_addr = 2;
                primary_path_table_miss();   

                ipv4_lpm.apply();
            }
            else {

                /* Check primary path port status */
                port_status = read_port_status.execute(ig_tm_md.ucast_egress_port);

                write_fork_switch_reg.execute(1);
                meta.src_addr = hdr.ipv4.src_addr;
                meta.dst_addr = hdr.ipv4.dst_addr;
                primary_path_table_hit();
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

    // action debug_digest() {
        
    // }
    // Output valid headers in the correct order
    apply {
        if(hdr.ipv4.isValid()){
            if(ig_dprsr_md.digest_type == 1){
                idigest.pack({
                    meta.ingress_tstamp,
                    meta.src_addr,
                    meta.dst_addr,
                    meta.table_hit
                });
            }
        }
        pkt.emit(hdr);
    }
}