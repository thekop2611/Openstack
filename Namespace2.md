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

5. Move 2 port vừa tạo vào 2 namespace DHCP tương ứng với nhau
	
	ip link set tap-r netns dhcp-r
	
	ip link set tap-g netns dhcp-g
	
6. Vào bash của các namespace DHCP và up các interface
	
	ip netns exec dhcp-r bash
	
	ip link set dev lo up
	
	ip link set dev tap-r up
	
	ip address add 10.50.50.2/24 dev tap-r
	
	Tương tự với dhcp-g
	
	ip netns exec dhcp-g bash
	
	ip link set dev lo up

	ip link set dev tap-g up

	ip address add 10.50.50.2/24 dev tap-g
	
7. Cấu hình dải địa chỉ DHCP cho namespace DHCP-R

	ip netns exec dhcp-r dnsmasq --interface=tap-r --dhcp-range=10.50.50.10,10.50.50.100,255.255.255.0
	
8. Check kết quả
	
	ps -ef | grep dns
	
	![image](https://user-images.githubusercontent.com/44855268/139176258-fd2578cb-bced-47d7-9ed9-07346ff02a95.png)
	
	Kết quả đạt yêu cầu.
