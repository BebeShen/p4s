import time
from ipaddress import ip_address

p4 = bfrt.p4frr.pipe

# for qsfp_cage in [1,2]:
#     for lane in range(0,4):
#         dp = bfrt.port.port_hdl_info.get(conn_id=qsfp_cage, chnl_id=lane, print_ents=False).data[b'$DEV_PORT']
#         bfrt.port.port.add(dev_port=dp, speed="BF_SPEED_10G", fec='BF_FEC_TYP_NONE', auto_negotiation='PM_AN_FORCE_DISABLE', port_enable=True)

########################    Install table entries   ########################

# print("Install table entries into tables:")
# # ncku csie
# p4.Ingress.ipv4_host.add_with_send(dst_addr=ip_address("10.0.0.187"), port=166)
# p4.Ingress.ipv4_host.add_with_send(dst_addr=ip_address("10.0.0.186"), port=132)


########################    Query port status       ########################
# for i in range(5):
#     print("Show port status, round: ", i)
#     print(bfrt.port.port.dump())
#     time.sleep(1)

for i in range(3):
    print("Show port status, round: ", i)
    # print(bfrt.port.port.dump())
    port_state = bfrt.port.port.get(0x00000084)
    port_name = port_state.data[b'$PORT_NAME']
    port_speed = port_state.data[b'$SPEED']
    print("Port {} is Up at {}bps".format(port_name, port_speed))
    print("===================================")
    time.sleep(1)
# print(bfrt.port.port.get(0x00000084))

def my_link_cb(dev_id, dev_port, up):
    port_state = bfrt.port.port.get(dev_port, print_ents = False)
    port_name = port_state.data[b'$PORT_NAME']
    port_speed = port_state.data[b'$SPEED'].split('_')[2]

    if up:
        print('Port {} is UP at {}bps'.format(port_name, port_speed))
    else:
        print('Port {} is DOWN at {}bps'.format(port_name))

def my_learning_cb(dev_id, pipe_id, direction, parser_id, session, msg):
    global p4
    smac = p4.Ingress.smac
    dmac = p4.Ingress.dmac
    for digest in msg:
        print(digest)
        # vid      = digest["vid"]
        # port     = digest["ingress_port"]
        # mac_move = digest["mac_move"]
        # mac      = digest["src_mac"]
        # old_port = port ^ mac_move # Because mac_move = ingress_port ^ port
        # print("VID=%d MAC=0x%012X Port=%d" % (vid, mac, port), end="")
        # if mac_move != 0:
        #     print("(Move from port=%d)" % old_port)
        # else:
        #     print("(New)")
    #     smac.entry_with_smac_hit (vid=vid, src_addr=mac, port=port, is_static=False,
    # ENTRY_TTL=60000).push()
    #     dmac.entry_with_dmac_unicast(vid=vid, dst_addr=mac, port=port).push()
    return 0
p4.IngressDeparser.l2_digest.callback_register(my_learning_cb)

# bfrt.port.port.port_status_notif_cb_set(callback=my_link_cb)

bfrt.complete_operations()
