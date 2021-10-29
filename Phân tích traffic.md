# Phân tích traffic
## VM tới DHCP

![image](https://user-images.githubusercontent.com/44855268/139409152-a86a8d3d-50cb-4618-9f07-475a0d39c5ac.png)

### Trên node compute

![image](https://user-images.githubusercontent.com/44855268/139408879-6c6a55a5-6dbe-49f1-b68b-8e2b131f4a16.png)

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
  
### Trên node controller
  
  ![image](https://user-images.githubusercontent.com/44855268/139408985-166cf733-f45f-4fe1-ad6d-52f71c3b1fb2.png)

  1. Dữ liệu tới switch br-int
  
  ovs-vsctl show
  
  ![image](https://user-images.githubusercontent.com/44855268/139364699-b8fe74fb-7baf-4cd3-942b-09bf2d709746.png)

  2. Bắt gói tin bằng tcp dump
  
  tcpdump -e -n -i eth0 | grep 192.0.2.85
  
  ![image](https://user-images.githubusercontent.com/44855268/139365314-0aeeeff2-b177-4745-8c15-3cc84a7b734f.png)

  3. Dump flow table trên br-int
  
  ![image](https://user-images.githubusercontent.com/44855268/139365750-0fbd3a7c-b557-4420-8ee6-c07127eed6d7.png)

  4. Dữ liệu đi vào tap interface tới DHCP namespace
  
  ![image](https://user-images.githubusercontent.com/44855268/139373900-82d9f1d6-b7e0-44ea-bba5-66c7c8cb1419.png)
  
### Traffic DHCP
  
  1. Create VM
  
  Khi có một request tạo VM, có một loạt các giao tiếp giữa nova tới glance, neutron để thực hiện tìm kiếm host, lấy IP, ... Sau khi các hành động trên thực thi xong, nova sẽ
  
  gọi tới hypervisor để khởi tạo. VM thực hiện khởi tạo sẽ xin cấp phát IP, ở bước này, DHCP namespace cấp IP cho VM và ghi lại thông tin.
  
  ![image](https://user-images.githubusercontent.com/44855268/139376227-03fea271-78e4-459c-9f8e-0d079c64d848.png)

  2. Restart VM
  
  Ở lần khởi động lại VM, VM vẫn thực hiện gửi gói tin DHCP, nhưng lần này kèm theo một gói tin release để cấp lại IP cũ
  
  ![image](https://user-images.githubusercontent.com/44855268/139377735-7e9a5915-5be6-4ef6-872a-4e214ebd24b7.png)

  3. Traffic metadata
  
  Sau khi gửi gói tin DHCP xong, VM sẽ thực hiện gửi request để lấy thông tin metadata từ nova. Mỗi lần VM khởi động đều gửi gói tin yêu cầu này
  
  ![image](https://user-images.githubusercontent.com/44855268/139376644-2d6250de-18d9-41e6-af26-040dccc2d1de.png)

  
  
  

