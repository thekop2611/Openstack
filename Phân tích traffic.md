# Phân tích traffic
## VM tới DHCP
### Trên node compute
  1. Xem port tap của VM
      [root@compute qemu]# cat instance-0000000a.xml
      <interface type='bridge'>
      <mac address='fa:16:3e:cb:50:13'/>
      <source bridge='br-int'/>
      <virtualport type='openvswitch'>
        <parameters interfaceid='82e9f482-502a-4847-8068-5ca800ed4765'/>
      </virtualport>
      <target dev='tap82e9f482-50'/>
  2. Kiểm tra switch br-int
      [root@compute qemu]# ovs-vsctl show
      d0ca1049-502a-458e-a7c9-5f4747c2ffc7
       Bridge br-int
        Controller "tcp:127.0.0.1:6633"
            is_connected: true
        fail_mode: secure
        datapath_type: system
        Port tap82e9f482-50
            tag: 1
            Interface tap82e9f482-50
  3. Kiểm tra switch br-vlan
      [root@compute qemu]# ovs-vsctl show
      Bridge br-tun
        Controller "tcp:127.0.0.1:6633"
            is_connected: true
        fail_mode: secure
        datapath_type: system
        Port patch-int
            Interface patch-int
                type: patch
                options: {peer=patch-tun}
        Port br-tun
            Interface br-tun
                type: internal
        Port vxlan-c0a82825
            Interface vxlan-c0a82825
                type: vxlan
                options: {df_default="true", egress_pkt_mark="0", in_key=flow, local_ip="192.168.40.31", out_key=flow, remote_ip="192.168.40.37"}
    ovs_version: "2.13.5"
  4. Dữ liệu được đóng gói và gửi ra ngoài thông qua interface eth0
  * Kiểm tra bằng lệnh tcpdump 
  1. Thực hiện ping từ VM
  VM địa chỉ IP 192.0.2.85 ping ra GW 192.0.2.2
  ![image](https://user-images.githubusercontent.com/44855268/139360611-31e759af-5bc7-481e-93ac-4e38689ad023.png)
  2. Gói tin gửi ra tap interface
  tcpdump -e -n -i tap82e9f482-50
  ![image](https://user-images.githubusercontent.com/44855268/139360668-cb00a06f-0e4f-4fa9-b23a-d7b229ec1c14.png)
  3. Kiểm tra flow table trên switch br-int
  ovs-ofctl dump-flows br-int
  ![image](https://user-images.githubusercontent.com/44855268/139362270-aadbb570-47cc-4d13-8f39-9f770bbf5f88.png)
  4. Gói tin ra eth0
  tcpdump -e -n -i eth0 | grep 192.0.2.2
  ![image](https://user-images.githubusercontent.com/44855268/139362608-c6553bcc-9f69-49ea-9128-d78dd2f5f542.png)
