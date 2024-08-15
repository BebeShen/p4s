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
    /* Variables */
    cur_number_t cur;
    flow_index_t flow;
    status_t     port_st;
    PortId_t     ig_port;
    PortId_t     out_port;

    /* Stateful Objects section */
    /* 
        Name     : Current DFS Number Register
        Index    : Flow
        Data     : Current DFS Number
    */
    Register<cur_number_t, flow_index_t>(FLOW_SIZE, 0) cur_register;
    RegisterAction<cur_number_t, flow_index_t, cur_number_t> (cur_register) read_cur = {
        void apply(inout cur_number_t register_data, out cur_number_t read_value){
            read_value = register_data;
        }
    }
    RegisterAction<cur_number_t, flow_index_t, cur_number_t> (cur_register) next_cur = {
        void apply(inout cur_number_t register_data, out cur_number_t write_value){
            register_data = register_data |+| 1;
            write_value = register_data;
        }
    }

    /* 
        Name     : Ingress Port Register
        Index    : Flow
        Data     : Ingress Port, init to 512
    */
    Register<ig_port_t, flow_index_t>(FLOW_SIZE, IG_PORT_INIT) ig_port_register;
    RegisterAction<ig_port_t, flow_index_t, ig_port_t> (ig_port_register) read_ig_port = {
        void apply(inout ig_port_t register_data, out ig_port_t read_value){
            read_value = register_data;
        }
    }
    RegisterAction<ig_port_t, flow_index_t, ig_port_t> (ig_port_register) write_ig_port = {
        void apply(inout ig_port_t register_data, out ig_port_t write_value){
            register_data = ig_intr_md.ingress_port;
            write_value = register_data;
        }
    }

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
    action recirculate(){
        ig_tm_md.ucast_egress_port[8:7] = ig_intr_md.ingress_port[8:7];
        ig_tm_md.ucast_egress_port[6:0] = RECIRCU_PORT;
    }
    action forwarding(){
        ig_tm_md.ucast_egress_port = out_port;
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
    action send() {
        ig_tm_md.ucast_egress_port = out_port;
    }
    action bounce_back() {
        ig_tm_md.ucast_egress_port = ig_intr_md.ingress_port;
        ig_tm_md.bypass_egress = 1;
    }

    action drop() {
        ig_dprsr_md.drop_ctl = 1;
    }


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

    table ipv4_host {
        key     = { hdr.ipv4.dst_addr : exact; }
        actions = {
            send; drop;
        }
        size = IPV4_HOST_TABLE_SIZE;
    }

    /* Main Ingress Logic */
    apply {
        if (hdr.ipv4.isValid()) {
            
            set_digest();

            // get flow
            addr_2_flow.apply();
            // get cur
            read_cur.execute(flow);
            // get Ingress Timestamp
            meta.ingress_tstamp = ig_intr_md.ingress_mac_tstamp;
            
            ig_port = read_ig_port(flow);

            // DEBUG
            meta.in_port = ig_port;
            
            if(ig_port == IG_PORT_INIT){
                write_ig_port.execute(flow);
            }
            
            /* Bounce Back or Recirculate packet received*/
            if(ig_intr_md.ingress_port != ig_port){
                next_cur(flow);
            }
            /* Resubmit */
            if(ig_intr_md.resubmit_flag == 1){
                next_cur(flow);
            }
            
            if(port_candi.apply().hit){

                // DEBUG
                meta.table_hit = 1;

                // out port is one of port candidate
                port_status.apply();
                
                // DEBUG
                meta.p_st = port_st;

                if(port_st == PortStatus_t.DOWN){
                    if(ig_intr_md.resubmit_flag == 1){
                        // already be a resubmit packet
                        recirculate();
                    }
                    else{
                        // resubmit
                        ig_dprsr_md.resubmit_type = 1;
                    }
                }
            }
            else{
                // DEBUG
                meta.table_hit = 0;
                // Bounce Back
                out_port = ig_port;
            }
            forwarding();
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
                    meta.p_st,
                    meta.in_port,
                    meta.out_port,
                    meta.table_hit
                });
            }
        }
        Resubmit() resubmit;
        if(ig_dprsr_md.resubmit_type == 1){
            resubmit.emit();
        }
        pkt.emit(hdr);
    }
}