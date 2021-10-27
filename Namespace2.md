1. Đầu tiên move các interface giao tiếp với OVS vào các Vlan 100 và 200

	ovs-vsctl set port veth-r tag=100
	
	ovs-vsctl set port veth-g tag=200
	
2. Vì dùng DHCP nên sẽ xoá các network đã set cho các namespace ở phần 1

	ip netns exec red ip address del 10.0.0.1/24 dev eth0-r
	
	ip netns exec green ip address del 10.0.0.2/24 dev eth0-g

3. Tạo thêm 2 namespace DHCP

	ip netns add dhcp-r
	
	ip netns add dhcp-g


4. Để kết nối với 2 DHCP namespace dùng internal port

	Tạo 2 internal port tap-g và tap-r
	
	ovs-vsctl add-port OVS1 tap-g -- set Interface tap-g type=internal
	
	
	ovs-vsctl add-port OVS1 tap-r -- set Interface tap-r type=internal
	
	Gắn tag cho 2 port tap-r và tap-g
	
	ovs-vsctl set port tap-r tag=100
	
	ovs-vsctl set port tap-g tag=200
  
  ![image](https://user-images.githubusercontent.com/44855268/139054086-6cbe501a-e46b-4e1c-95cb-31b358aae5a8.png)

5. ![image](https://user-images.githubusercontent.com/44855268/139054141-bb6ee00c-4757-4e15-9844-497e0cfb5d37.png)
