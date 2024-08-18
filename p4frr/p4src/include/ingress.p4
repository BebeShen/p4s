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
        transition select(ig_intr_md.resubmit_flag){
            1: parse_resubmit;
            0: parse_port_metadata;
        }
        // pkt.advance(PORT_METADATA_SIZE);
        // transition parse_ethernet;
    }

    /* Parse Resubmit */
    state parse_resubmit {
        pkt.advance(PORT_METADATA_SIZE);
        transition parse_ethernet;
    }
    /* Parse Port Metadata */
    state parse_port_metadata {
        meta = port_metadata_unpack<my_ingress_metadata_t>(pkt);
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
    /* Variables */
    cur_number_t cur = 0;
    flow_index_t flow = 0;
    status_t     port_st = 0;
    PortId_t     ig_port = 0;
    PortId_t     out_port = 0;

    /* Stateful Objects section */
    /* 
        Name     : Current DFS Number Register
        Index    : Flow
        Data     : Current DFS Number
    */
    Register<bit<16>, flow_index_t>(256, 0) cur_register;
    RegisterAction<bit<16>, flow_index_t, bit<16>> (cur_register) read_cur = {
        void apply(inout bit<16> register_data, out bit<16> read_value){
            read_value = register_data;
        }
    };
    RegisterAction<bit<16>, flow_index_t, bit<16>> (cur_register) next_cur = {
        void apply(inout bit<16> register_data, out bit<16> write_value){
            register_data = register_data |+| 1;
            write_value = register_data;
        }
    };

    /* 
        Name     : Ingress Port Register
        Index    : Flow
        Data     : Ingress Port, init to 512
    */
    Register<bit<16>, flow_index_t>(FLOW_SIZE, IG_PORT_INIT) ig_port_register;
    RegisterAction<bit<16>, flow_index_t, bit<16>> (ig_port_register) read_ig_port = {
        void apply(inout bit<16> register_data, out bit<16> read_value){
            if(register_data == IG_PORT_INIT){
                register_data = (bit<16>)ig_intr_md.ingress_port;
            }
            read_value = register_data;
        }
    };
    RegisterAction<bit<16>, flow_index_t, bit<16>> (ig_port_register) write_ig_port = {
        void apply(inout bit<16> register_data, out bit<16> write_value){
            register_data = (bit<16>)ig_intr_md.ingress_port;
            write_value = register_data;
        }
    };

    /* Action section */
    action get_flow(flow_index_t f){
        flow = f;
    }
    action get_port_candi(PortId_t p){
        out_port = p;
    }
    action get_port_status(status_t st){
        port_st = st;
    }
    // action recirculate(){
    //     ig_tm_md.ucast_egress_port[8:7] = ig_intr_md.ingress_port[8:7];
    //     ig_tm_md.ucast_egress_port[6:0] = RECIRCU_PORT;
    // }
    // action send(){
    //     ig_tm_md.ucast_egress_port = out_port;
    // }
    // action set_digest(){
    //     ig_dprsr_md.digest_type = 1;
    // }
    // action drop() {
    //     ig_dprsr_md.drop_ctl = 1;
    // }


    /* Table section */
    table addr_2_flow {
        key     = {
            hdr.ipv4.src_addr   :   exact;
            hdr.ipv4.dst_addr   :   exact;
        }
        actions = {
            get_flow;
        }
        size    = ADDR_2_FLOW_TABLE_SIZE;
    }

    table port_candi {
        key     = {
            flow    :   exact;
            cur     :   exact;
        }
        actions = {
            get_port_candi;
        }
        size    = PORT_CANDI_TALBE_SIZE;
    }

    table port_status {
        key     = {
            out_port    :   exact;
        }
        actions = {
            get_port_status;
        }
        size    = PORT_STATUS_TALBE_SIZE;
    }

    /* Main Ingress Logic */
    apply {

        // get Ingress Timestamp
        // meta.ingress_tstamp = ig_intr_md.ingress_mac_tstamp;
        // meta.in_port = 0;
        meta.resubmit_f = 0;
        meta.out_port = 0;
        meta.p_st = 0;

        // get flow
        if(addr_2_flow.apply().hit){

            meta.flow = flow;

            // get flow ingress port
            ig_port = (PortId_t)read_ig_port.execute(flow);
            // DEBUG
            // meta.in_port = ig_intr_md.ingress_port;

            /* Bounce Back or Recirculate packet received*/
            if(ig_intr_md.ingress_port != ig_port){
                meta.resubmit_f = 2;
                next_cur.execute(flow);
            }
            /* Resubmit */
            else if(ig_intr_md.resubmit_flag == 1){
                meta.resubmit_f = 1;
                next_cur.execute(flow);
            }

            // get cur
            cur = (cur_number_t)read_cur.execute(flow);
            meta.cur = cur;
            
            // set_digest();
            ig_dprsr_md.digest_type = 1;
        
            if(port_candi.apply().hit){
                // out port is one of port candidate
                port_status.apply();
                // DEBUG
                meta.p_st = port_st;

                if(port_st == PortStatus_t.DOWN){
                    if(ig_intr_md.resubmit_flag == 1){
                        // already be a resubmit packet
                        // recirculate();
                        out_port[8:7] = ig_intr_md.ingress_port[8:7];
                        out_port[6:0] = RECIRCU_PORT;
                    }
                    else{
                        // resubmit
                        ig_dprsr_md.resubmit_type = 1;
                    }
                }
            }
            else{
                // Bounce Back
                out_port = ig_port;
                ig_tm_md.bypass_egress = 1;
            }
            meta.out_port = out_port;
            ig_tm_md.ucast_egress_port = out_port;
        }
        else{
            // drop
            ig_dprsr_md.drop_ctl = 1;
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

    Resubmit() resubmit;
    apply {
        if(hdr.ipv4.isValid()){
            if(ig_dprsr_md.digest_type == 1){
                idigest.pack({
                    hdr.ipv4.src_addr,
                    hdr.ipv4.dst_addr,
                    meta.flow,
                    meta.cur,
                    meta.resubmit_f,
                    meta.p_st,
                    // meta.in_port,
                    meta.out_port
                });
            }
        }
        if(ig_dprsr_md.resubmit_type == 1){
            resubmit.emit();
        }
        pkt.emit(hdr);
    }
}