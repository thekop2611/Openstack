1. Đầu tiên check ip link và ip address, ip route

	ip link
  
  ![ip link 1](https://user-images.githubusercontent.com/44855268/139041447-2cb82a63-17b0-474b-abba-ac78d714cb33.PNG)

	ip address
  
  ![ip address 1](https://user-images.githubusercontent.com/44855268/139041439-b0f174eb-0bff-4c6d-891d-ac495f16d58c.PNG)

	ip route
  
  ![ip route 1](https://user-images.githubusercontent.com/44855268/139041481-3e52d332-0843-4d5d-afbf-4de494e4bbd4.PNG)

2. Tạo 2 namespace red và green 

	ip netns exec add red
	
	ip netns exec add green
  
  ![add green red](https://user-images.githubusercontent.com/44855268/139041582-e1c8b07a-519b-4f5f-a0d1-24366ea9e30a.PNG)
	
	ip netns
	
3. Gán ip link cho các namespace
	
	ip netns exec red ip link
	
	ip netns exec green ip link
  
  ![ip netns red green ip link](https://user-images.githubusercontent.com/44855268/139041691-09c2b940-d25a-4390-90f6-7e106056020c.PNG)

4. Add bridge OVS1
	
	ovs-vsctl add-br OVS1
  
	ovs-vsctl show
  
  ![OVS1 add-br](https://user-images.githubusercontent.com/44855268/139041795-025ad9cb-4b1f-4059-a8c5-f343b6990f52.PNG)

5. Tạo cặp V-eth để kết nối các namespace tới switch
	
	- Với red namespace
	
	ip link add eth0-r type veth peer name veth-r (tạo)
	
	ip link set eth0-r netns red (gán)
	
	ip netns exec red ip link (check)
  
  ![check red veth](https://user-images.githubusercontent.com/44855268/139041921-5da5a7ff-8cc3-4e7c-a18d-dea90ddaa1f2.PNG)

	
	- Tương tự với green namespace
	
	ip link add etho-g type veth peer name veth-g
	
	ip link set eth0-g netns green
  
  ![check all veth](https://user-images.githubusercontent.com/44855268/139042927-2ab40574-a9a5-4873-9aa2-36bf5cc9d559.PNG)

	
6. Gán đầu còn lại của cặp V-eth vào OVS
  
  ovs-vsctl add-port OVS1 veth-r
  
  ovs-vsctl add-port OVS1 veth-g
  
  ![gán veth vào OVS1](https://user-images.githubusercontent.com/44855268/139042754-65ffd86e-6c3d-47b8-9421-f4d37652b87c.PNG)

7. Up các interface và gán network cho namespace

	- Với red namespace

	ip netns exec red ip link set dev lo up
	
	ip netns exec red ip link set dev eth0-r up
	
	ip netns exec red ip address add 10.0.0.1/24 dev eth0-r
	
	ip netns exec red ip a (check)
  
  ![gán network cho red](https://user-images.githubusercontent.com/44855268/139042979-9986acb1-cc93-489b-aba9-8dedf09de229.PNG)

	
	- Tương tự với green namespace
	
	- Thử chuyển sang red và ping sang green
	
	ip netns exec red bash
	
	ping 10.0.0.2
	
PING 10.0.0.2 (10.0.0.2) 56(84) bytes of data.
64 bytes from 10.0.0.2: icmp_seq=1 ttl=64 time=0.412 ms
64 bytes from 10.0.0.2: icmp_seq=2 ttl=64 time=0.049 ms
  
  Ping thành công là hoàn thành.
  
  
