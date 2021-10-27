4. Để kết nối với 2 DHCP namespace dùng internal port

	Tạo 2 internal port tap-g và tap-r
	
	ovs-vsctl add-port OVS1 tap-g -- set Interface tap-g type=internal
	
	ovs-vsctl add-port OVS1 tap-r -- set Interface tap-r type=internal
  
  ![image](https://user-images.githubusercontent.com/44855268/139054086-6cbe501a-e46b-4e1c-95cb-31b358aae5a8.png)

5. ![image](https://user-images.githubusercontent.com/44855268/139054141-bb6ee00c-4757-4e15-9844-497e0cfb5d37.png)
