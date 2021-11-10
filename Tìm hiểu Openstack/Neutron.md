# OpenStack Networking cơ bản

## Mục lục

### [1. Giới thiệu chung về Neutron](#intro)

### [2. Các khái niệm](#concepts)

### [3. Cấu trúc thành phần và dịch vụ](#contents)

- [3.1 Server](#server)
- [3.2 Plug-ins](#plugin)
- [3.3 Agents](#agents)
- [3.4 Services](#service)

---------

### <a name="intro"> 1. Giới thiệu chung về Neutron </a>

OpenStack Networking cho phép bạn tạo và quản lí các network objects ví dụ như networks, subnets, và ports cho các services khác của OpenStack sử dụng.  Với kiến trúc plugable, các plug-in có thể được sử dụng để triển khai các thiết bị và phần mềm khác nhau, nó khiến OpenStack có tính linh hoạt trong kiến trúc và triển khai.

Dịch vụ Networking trong OpenStack (neutron) cũng cấp API cho phép bạn định nghĩa các kết nối mạng và gán địa chỉ ở trong môi trường cloud. Nó cũng cho phép các nhà khai thác vận hành các công nghệ networking khác nhau cho phù hợp với mô hình điện toán đám mây của riêng họ. Neutron cũng cung cấp một API cho việc cấu hình cũng như quản lí các dịch vụ networking khác nhau từ L3 forwarding, NAT cho tới load balancing, perimeter firewalls, và virtual private networks.

Neutron có những thành phần sau:

**API server**

OpenStack Networking API hỗ trợ Layer2 networking và IP address management (IPAM - quản lý địa chỉ IP), cũng như một extension để xây dựng router Layer 3 cho phép định tuyến giữa các networks Layer 2 và các gateway để ra mạng bên ngoài. OpenStack Networking cung cấp một danh sách các plug-ins (đang ngày càng tăng lên) cho phép tương tác với nhiều công nghệ mạng mã nguồn mở và cả thương mại, bao gồm các routers, switches, switch ảo và SDN controller.

**OpenStack Networking plug-in and agents**

Các plugin và các agent này cho phép gắn và gỡ các ports, tạo ra network hay subnet, và đánh địa chỉ IP. Lựa chọn plugin và agents nào là tùy thuộc vào nhà cung cấp và công nghệ sử dụng trong hệ thống cloud nhất định. Điều quan trọng là tại một thời điểm chỉ sử dụng được một plug-in.

**Messaging queue**

Tiếp nhận và định tuyến các RPC requests giữa các agents để hoàn thành quá trình vận hành API. Các Message queue được sử dụng trong ML2 plugin để thực hiện truyền thông RPC giữa neutron server và các neutron agents chạy trên mỗi hypervisor, cụ thể là các ML2 driver cho Open vSwitch và Linux bridge.

### <a name ="concepts"> 2. Các khái niệm </a>

Với neutron, bạn có thể tạo và cấu hình các networks, subnets và thông báo tới Compute để gán các thiết bị ảo vào các ports của mạng vừa tạo. OpenStack Compute chính là "khách hàng" của neutron, chúng liên kết với nhau để cung cấp kết nối mạng cho các máy ảo. Cụ thể hơn, OpenStack Networking hỗ trợ cho phép các projects có nhiều private networks và các projects có thể tự chọn danh sách IP cho riêng mình, kể cả những IP đã được sử dụng bởi một project khác.  Có hai loại network đó là project và provider.

**Provider networks**

Provider networks cung cấp kết nối layer 2 cho các máy ảo với các tùy chọn hỗ trợ cho dịch vụ DHCP và metadata. Các kết nối này thường sử dụng VLAN (802.1q) để nhận diện và tách biệt nhau.

Nhìn chung, Provider networks cũng cấp sự đơn giản, hiệu quả và sự minh bạch, linh hoạt trong chi phí. Mặc định chỉ có duy nhất người quản trị mới có thể tạo hoặc cập nhật provider networks bởi nó yêu cầu phải cấu hình thiết bị vật lí. Bạn cũng có thể thay đổi quyền cho phép user khác tạo hoặc update provider networks bằng cách thêm 2 câu sau vào file `policy.json` : 

``` sh 
create_network:provider:physical_network
update_network:provider:physical_network
```

Bên cạnh đó, provider networks chỉ quản lí kết nối ở layer 2 cho máy ảo, vì thế nó thiếu đi một số tính năng ví dụ như định tuyến và gán floating IP.

Các nhà khai thác đã quen thuộc với kiến trúc mạng ảo dựa trên nền tảng mạng vật lí cho layer 2, layer 3 và các dịch vụ khác có thể dễ dàng triển khai OpenStack Networking service. Provider networks cũng khiến các nhà khai thác muốn chuyển từ Compute networking service (nova-network) sang OpenStack Networking service.

Vì các thành phần chịu trách nhiệm cho việc vận hành kết nối layer 3 sẽ ảnh hưởng tới hiệu năng và tính tin cậy nên provider networks chuyển các kết nối này xuống tầng vật lí.

**Routed provider networks**

Routed provider networks cung cấp kết nối ở layer 3 cho các máy ảo. Các network này map với những networks layer 3 đã tồn tại. Cụ thể hơn, các  layer-2 segments của provider network sẽ được gán các router gateway giúp chúng có thể được định tuyến ra bên ngoài chứ thực chất Networking service không cung cấp khả năng định tuyến. Routed provider networks tất nhiên sẽ có hiệu suất thấp hơn so với provider networks.

**Self-service networks**

Self-service networks được ưu tiên ở các projects thông thường để quản lí networks mà không cần quản trị viên (quản lí network trong project). Các networks này là ảo và nó yêu cầu các routers ảo để giao tiếp với provider và external networks. Self-service networks cũng đồng thời cung cấp dịch vụ DHCP và metadata cho máy ảo.

Trong hầu hết các trường hợp, self-service networks  sử dụng các giao thức như VXLAN hoặc GRE bởi chúng hỗ trợ nhiều hơn là VLAN tagging (802.1q). Bên cạnh đó, Vlans cũng thường yêu cầu phải cấu hình thêm ở tầng vật lí.

Với IPv4, self-service networks thường sử dụng dải mạng riêng và tương tác với provider networks thông qua cơ chế NAT trên router ảo.  Floating IP sẽ cho phép kết nối tới máy ảo thông qua địa chỉ NAT trên router ảo. Trong khi đó, IPv6 self-service networks thì lại sử dụng dải IP public và tương tác với provider networks bằng giao thức định tuyến tĩnh qua router ảo.

Trái ngược lại với provider networks, self-service networks buộc phải đi qua  layer-3 agent. Vì thế việc gặp sự cố ở một node có thể ảnh hưởng tới rất nhiều các máy ảo sử dụng chúng. 

Các user có thể tạo các project networks cho các kết nối bên trong project. Mặc định thì các kết nối này là riêng biệt và không được chia sẻ giữa các project. OpenStack Networking hỗ trợ các công nghệ dưới đây cho project network:

- **Flat** 

Tất cả các instances nằm trong cùng một mạng, và có thể chia sẻ với hosts. Không hề sử dụng VLAN tagging hay hình thức tách biệt về network khác.

- **VLAN**

Kiểu này cho phép các users tạo nhiều provider hoặc project network sử dụng VLAN IDs(chuẩn 802.1Q tagged) tương ứng với VLANs trong mạng vật lý. Điều này cho phép các instances giao tiếp với nhau trong môi trường cloud. Chúng có thể giao tiếp với servers, firewalls, load balancers vật lý và các hạ tầng network khác trên cùng một VLAN layer 2.

- **GRE and VXLAN**

VXLAN và GRE là các giao thức đóng gói tạo nên overlay networks để kích hoạt và kiểm soát việc truyền thông giữa các máy ảo (instances). Một router được yêu cầu để cho phép lưu lượng đi ra luồng bên ngoài tenant network GRE hoặc VXLAN. Router cũng có thể yêu cầu để kết nối một tenant network với mạng bên ngoài (ví dụ Internet). Router cung cấp khả năng kết nối tới instances trực tiếp từ mạng bên ngoài sử dụng các địa chỉ floating IP.

<img src="http://i.imgur.com/He8ttC7.png">

**Subnets**

Là một khối tập hợp các địa chỉ IP và đã được cấu hình. Quản lý các địa chỉ IP của subnet do IPAM driver thực hiện. Subnet được dùng để cấp phát các địa chỉ IP khi ports mới được tạo trên network.

**Subnet pools**

Người dùng cuối thông thường có thể tạo các subnet với bất kì địa chỉ IP hợp lệ nào mà không bị hạn chế. Tuy nhiên, trong một vài trường hợp, sẽ là ổn hơn nếu như admin hoặc tenant định nghĩa trước một pool các địa chỉ để từ đó tạo ra các subnets được cấp phát tự động. 
Sử dụng subnet pools sẽ ràng buộc những địa chỉ nào có thể được sử dụng bằng cách định nghĩa rằng mỗi subnet phải nằm trong một pool được định nghĩa trước. Điều đó ngăn chặn việc tái sử dụng địa chỉ hoặc bị chồng lấn hai subnets trong cùng một pool.

**Ports**

Là điểm kết nối để attach một thiết bị như card mạng của máy ảo tới mạng ảo. Port cũng được cấu hình các thông tin như địa chỉ MAC, địa chỉ IP để sử dụng port đó.

**Router**

Cung cấp các dịch vụ layer 3 ví dụ như định tuyến, NAT giữa các self service và provider network hoặc giữa các self service với nhau trong cùng một project. 

**Security groups**

Một security groups được coi như một firewall ảo cho các máy ảo để kiểm soát lưu lượng bên trong và bên ngoài router. Security groups hoạt động mức port, không phải mức subnet. Do đó, mỗi port trên một subnet có thể được gán với một tập hợp các security groups riêng. Nếu không chỉ định group cụ thể nào khi vận hành, máy ảo sẽ được gán tự động với default security group của project. Mặc định, group này sẽ hủy tất cả các lưu lượng vào và cho phép lưu lượng ra ngoài. Các rule có thể được bổ sung để thay đổi các hành vi đó. 
Security group và các security group rule cho phép người quản trị và các tenant chỉ định loại traffic và hướng (ingress/egress) được phép đi qua port. Một security group là một container của các security group rules.

Các rules trong security group phụ thuộc vào nhau. Vì thế nếu bạn cho phép inbound TCP port 22, hệ thống sẽ tự động tạo ra 1 rule cho phép outbound traffic trả lại và ICMP error messages liên quan tới các kết nối TCP vừa được tạo rules.

Mặc định, mọi security groups chứa các rules thực hiện một số hành động sau:

- Cho phép traffic ra bên ngoài chỉ khi nó sử dụng địa chỉ MAC và IP của port máy ảo, cả hai địa chỉ này được kết hợp tại `allowed-address-pairs`
- Cho phép tín hiệu tìm kiếm DHCP và gửi message request sử dụng MAC của port cho máy ảo và địa chỉ IP chưa xác định.
- Cho phép trả lời các tín hiệu DHCP và DHCPv6 từ DHCP server để các máy ảo có thể lấy IP
- Từ chối việc trả lời các tín hiệu DHCP request từ bên ngoài để tránh việc máy ảo trở thành DHCP server
- Cho phép các tín hiệu inbound/outbound ICMPv6 MLD, tìm kiếm neighbors, các máy ảo nhờ vậy có thể tìm kiếm và gia nhập các multicast group.
- Từ chối các tín hiệu outbound ICMPv6 để ngăn việc máy ảo trở thành IPv6 router và forward các tín hiệu cho máy ảo khác.
- Cho phép tín hiệu outbound non-IP từ địa chỉ MAC của các port trên máy ảo .

Mặc dù cho phép non-IP traffic nhưng security groups không cho phép các ARP traffic. Có một số rules để lọc các tín hiệu ARP nhằm ngăn chặn việc sử dụng nó để chặn tín hiệu tới máy ảo khác. Bạn không thể xóa hoặc vô hiệu hóa những rule này.
Bạn có thể hủy  security groups bằng các sửa giá trị dòng `port_security_enabled` thành `False`.

**Extensions**

OpenStack Networking service có khả năng mở rộng. Có hai mục đích chính cho việc này: cho phép thực thi các tính năng mới trên API mà không cần phải đợi đến khi ra bản tiếp theo và cho phép các nhà phân phối bổ sung những chức năng phù hợp. Các ứng dụng có lấy danh sách các extensions có sẵn sử dụng phương thức GET trên /extensions URI. Chú ý đây là một request phụ thuộc vào phiên bản OpenStack, một extension trong một API ở phiên bản này có thể không sử dụng được cho phiên bản khác.

**DHCP**

Dịch vụ tùy chọn DHCP quản lí địa chỉ IP trên provider và self-service networks. Networking service triển khai DHCP service sử dụng agent quản lí qdhcp namespaces và dnsmasq service.

**Metadata**

Dịch vụ tùy chọn cung cấp API cho máy ảo để lấy metadata ví dụ như SSH keys.

**Open vSwitch**

OpenvSwitch (OVS) là công nghệ switch ảo hỗ trợ SDN (Software-Defined Network), thay thế Linux bridge. OVS cung cấp chuyển mạch trong mạng ảo hỗ trợ các tiêu chuẩn Netflow, OpenFlow, sFlow. OpenvSwitch cũng được tích hợp với các switch vật lý sử dụng các tính năng lớp 2 như STP, LACP, 802.1Q VLAN tagging. OVS tunneling cũng được hỗ trợ để triển khai các mô hình network overlay như VXLAN, GRE.

**L3 Agent**

L3 agent là một phần của package openstack-neutron. Nó được xem như router layer3 chuyển hướng lưu lượng và cung cấp dịch vụ gateway cho network lớp 2. Các nodes chạy L3 agent không được cấu hình IP trực tiếp trên một card mạng mà được kết nối với mạng ngoài. Thay vì thế, sẽ có một dải địa chỉ IP từ mạng ngoài được sử dụng cho OpenStack networking. Các địa chỉ này được gán cho các routers mà cung cấp liên kết giữa mạng trong và mạng ngoài. Miền địa chỉ được lựa chọn phải đủ lớn để cung cấp địa chỉ IP duy nhất cho mỗi router khi triển khai cũng như mỗi floating IP gán cho các máy ảo.

- **DHCP Agent:** OpenStack Networking DHCP agent chịu trách nhiệm cấp phát các địa chỉ IP cho các máy ảo chạy trên network. Nếu agent được kích hoạt và đang hoạt động khi một subnet được tạo, subnet đó mặc định sẽ được kích hoạt DHCP.
- **Plugin Agent:** Nhiều networking plug-ins được sử dụng cho agent của chúng, bao gồm OVS và Linux bridge. Các plug-in chỉ định agent chạy trên các node đang quản lý lưu lượng mạng, bao gồm các compute node, cũng như các nodes chạy các agent

### < name ="content"> 3. Cấu trúc thành phần và dịch vụ </a>

#### 3.1 Server

Cung cấp API, quản lí database,...

#### 3.2 Plug-ins

Quản lí agents

#### 3.3 Agents

- Cung cấp kết nối layer 2/3 tới máy ảo
- Xử lý truyền thông giữa mạng ảo và mạng vật lý.
- Xử lý metadata, etc.

##### Layer 2 (Ethernet and Switching)

- Linux Bridge
- OVS

##### Layer 3 (IP and Routing)

- L3
- DHCP

##### Miscellaneous

- Metadata

#### Services

Các dịch vụ Routing

- VPNaaS: Virtual Private Network-as-a-Service (VPNaaS), extension của neutron cho VPN
- LBaaS: Load-Balancer-as-a-Service (LBaaS), API quy định và cấu hình nên các load balancers, được triển khai dựa trên HAProxy software load balancer.
- FWaaS: Firewall-as-a-Service (FWaaS), API thử nghiệm cho phép các nhà cung cấp kiểm thử trên networking của họ.

# Tìm hiểu Open vSwitch

## Mục lục

1. Giới thiệu về SDN (Software Defined Networking) và Open Flow

2. Giới thiệu Open vSwitch

3. Những hạn chế khi sử dụng Linux Bridge - So sánh Open vSwitch và Linux Bridge

4. Cấu trúc của Open vSwitch

5. Hướng dẫn cài đặt KVM với Open vSwitch

6. Một vài câu lệnh với Open vSwitch

--------

## 1. Giới thiệu về SDN (Software Defined Networking) và Open Flow

**SDN (Software Defined Networking)**

SDN (Software Defined Networking) hay mạng điều khiển bằng phần mềm là một kiến trúc đem tới sự tự động, dễ dàng quản lí, tiết kiệm chi phí và có tính tương thích cao, đặc biệt phù hợp với những ứng dụng yêu cầu tốc độ băng thông cũng như sự tự dộng ngày nay. Kiến trúc này tách riêng hai chức năng là quản lí và truyền tải dữ liệu. SDN dựa trên giao thức luồng mở (Open Flow) và là kết quả nghiên cứu của Đại học Stanford và California Berkeley. SDN tách định tuyến và chuyển các luồng dữ liệu riêng rẽ và chuyển kiểm soát luồng sang thành phần mạng riêng có tên gọi là thiết bị kiểm soát luồng (Flow Controller).

Tóm lại có 3 ý chính đối với SDN đó là:

- Tách biệt phần quản lí (control plane) với phần truyền tải dữ liệu (data plane).
- Các thành phần trong network có thể được quản lí bởi các phần mềm được lập trình chuyên biệt.
- Tập trung vào kiểm soát và quản lí network.

Cùng quay trở lại quá khứ, khi mà người ta vẫn sử dụng Ethernet Hub. Về bản chất, thiết bị này chỉ làm công việc lặp đi lặp lại đó là mỗi khi nhận dữ liệu, nó lại forward tới tất cả các port mà nó kết nối.

Tuy nhiên điều này có thể gây nên nhiều hệ lụy xấu như broadcast storms, bandwidth bị giảm và looping (lụt). Kiểu truyền tải dữ liệu này được gọi là Data Plane/Forwarding Plane. Đó là lí do vì sao nó nhanh chóng bị thay thế bởi thiết bị layer 2 hay còn được biết tới với cái tên Network Switch. Thiết bị này về cơ bản đã "thông minh" hơn rất nhiều khi mà nó biết gửi dữ liệu tới đúng interface, và từ đây khái niệm control plane cũng bắt đầu xuất hiện.

Các thiết bị mạng đều có sự xuất hiện của control plane, nó cung cấp thông tin để xây lên bảng kết nối giúp các thiết bị mạng biết được chính xác nơi cần gửi dữ liệu.

<img src="http://i.imgur.com/lleKL7G.png">

Dưới đây là mô hình của kiến trúc SDN

<img src="http://i.imgur.com/0f19CtI.png">

Nhìn chung, SDN có 3 phần chính đó là:

- Network infrastructure: Bao gồm các thiết bị mạng như router, switch, bao gồm cả thiết bị ảo và thật.
- Controller: Bao gồm phần mềm dựa trên bộ điều khiển tập trung, có thể đặt trên server để giao tiếp với tất cả các thiết bị mạng bằng cách sử dụng API như OpenFlow hoặc OVMDB.

- Applications: Bao gồm hàng loạt các ứng dụng có sự tồn tại của network. Các ứng dụng này có thể nói chuyện với controller sử dụng API để thực hiện những yêu cầu.

**Open Flow**

OpenFlow là tiêu chuẩn đầu tiên, cung cấp khả năng truyền thông giữa các giao diện của lớp điều khiển và lớp chuyển tiếp trong kiến trúc SDN. OpenFlow cho phép truy cập trực tiếp và điều khiển mặt phẳng chuyển tiếp của các thiết bị mạng như switch và router, cả thiết bị vật lý và thiết bị ảo, do đó giúp di chuyển phần điều khiển mạng ra khỏi các thiết bị chuyển mạch thực tế tới phần mềm điều khiển trung tâm.
Các quyết định về các luồng traffic sẽ được quyết định tập trung tại OpenFlow Controller giúp đơn giản trong việc quản trị cấu hình trong toàn hệ thống.
Một thiết bị OpenFlow bao gồm ít nhất 3 thành phần:

- Secure Channel: kênh kết nối thiết bị tới bộ điều khiển (controller), cho phép các lệnh và các gói tin được gửi giữa bộ điều khiển và thiết bị.
- OpenFlow Protocol: giao thức cung cấp phương thức tiêu chuẩn và mở cho một bộ điều khiển truyền thông với thiết bị.
- Flow Table: một liên kết hành động với mỗi luồng, giúp thiết bị xử lý các luồng.

<img src="http://i.imgur.com/t4SOR63.png">


## 2. Giới thiệu OpenvSwitch

Open vSwitch là switch ảo mã nguồn mở theo giao thức OpenFlow. Nó là một multilayer software được viết bằng ngôn ngữ C cung cấp cho người dùng các chức năng quản lí network interface.

Open vSwitch rất phù hợp với chức năng là một switch ảo trong môi trường ảo hóa. Nó hỗ trợ rất nhiều nền tảng như Xen/XenServer, KVM, và VirtualBox.

Các chức năng của Open vSwitch:

- Standard 802.1Q VLAN model with trunk and access ports
- NIC bonding with or without LACP on upstream switch
- NetFlow, sFlow(R), and mirroring for increased visibility
- QoS (Quality of Service) configuration, plus policing
- Geneve, GRE, VXLAN, STT, and LISP tunneling
- 802.1ag connectivity fault management
- OpenFlow protocol support
- Transactional configuration database with C and Python bindings
- High-performance forwarding using a Linux kernel module

## 3. Những hạn chế khi sử dụng Linux Bridge - So sánh OpenvSwitch và Linux Bridge

**Hạn chế của Linux Bridge**

Linux Bridge (LB) là cơ chế ảo hóa mặc định được sử dụng trong KVM. Nó rất dễ dàng để cấu hình và quản lí tuy nhiên nó vốn không được dùng cho mục đích ảo hóa vì thế bị hạn chế một số các chức năng.

LB không hỗ trợ tunneling và OpenFlow protocols. Điều này khiến nó bị hạn chế trong việc mở rộng các chức năng. Đó cũng là lí do vì sao  Open vSwitch xuất hiện.

Dưới đây là bảng so sánh giữa hai công nghệ này:

| Open vSwitch | Linux bridge |
|--------------|--------------|
| Được thiết kế cho môi trường mạng ảo hóa | Mục đích ban đầu không phải dành cho môi trường ảo hóa |
| Có các chức năng của layer 2-4 | Chỉ có chức năng của layer 2 |
| Có khả năng mở rộng | Bị hạn chế về quy mô |
| ACLs, QoS, Bonding | Chỉ có chức năng forwarding |
| Có OpenFlow Controller | Không phù hợp với môi trường cloud |
| Hỗ trợ netflow và sflow | Không hỗ trợ tunneling |

**OVS**

- Ưu điểm: các tính năng tích hợp nhiều và đa dạng, kế thừa từ linux bridge. OVS hỗ trợ ảo hóa lên tới layer4. Được sự hỗ trợ mạnh mẽ từ cộng đồng. Hỗ trợ xây dựng overlay network.

- Nhược điểm: Phức tạp, gây ra xung đột luồng dữ liệu

**LB**

- Ưu điểm:

các tính năng chính của switch layer được tích hợp sẵn trong nhân. Có được sự ổn định và tin cậy, dễ dàng trong việc troubleshoot
Less moving parts: được hiểu như LB hoạt động 1 cách đơn giản, các gói tin được forward nhanh chóng

- Nhược điểm:

để sử dụng ở mức user space phải cài đặt thêm các gói. VD vlan, ifenslave. Không hỗ trợ openflow và các giao thức điều khiển khác.
không có được sự linh hoạt


## 4. Các thành phần và kiến trúc của Open vSwitch

Các thành phần chính của Open vSwitch:

- ovs-vswitchd :  daemon tạo ra switch, nó được đi kèm với Linux kernel module
- ovsdb-server : Một máy chủ cơ sở dữ liệu nơi ovs-vswitchd truy vấn để có được cấu hình.
- ovs-dpctl : công cụ để cấu hình switch kernel module.
- ovs-vsctl : Dùng để truy vấn và cập nhật cấu hình cho ovs-vswitchd.
- ovs-appctl : Dùng để gửi câu lệnh chạy Open vSwitch daemons.

<img src="http://i.imgur.com/BveiREY.jpg">

**Cơ chế hoạt động**

Nhìn chung Open vSwitch được chia làm phần, Open vSwitch kernel module (Data Plane) và user space tools (Control Plane).

OVS kernel module sẽ dùng netlink socket để tương tác với vswitchd daemon để tạo và quản lí số lượng OVS switches trên hệ thống local. SDN Controller sẽ tương tác với vswitchd sử dụng giao thức OpenFlow. ovsdb-server chứa bảng dữ liệu. Các clients từ bên ngoài cũng có thể tương tác với ovsdb-server sử dụng json rpc với dữ liệu theo dạng file JSON.

Open vSwitch có 2 modes, normal và flow:
- Normal Mode: Ở mode này, Open vSwitch tự quản lí tất cả các công việc switching/forwarding. Nó hoạt động như một switch layer 2.

- Flow Mode: Ở mode này, Open vSwitch dùng flow table để quyết định xem port nào sẽ nhận packets. Flow table được quản lí bởi SDN controller nằm bên ngoài.

<img src="http://i.imgur.com/G4PxNjC.png">

## 5. Hướng dẫn cài đặt KVM với OpenvSwitch

**Mô hình**

- Môi trường lab: KVM
- 1 máy Ubuntu 14.04 có 2 NICs, 1 NIC bridge và 1 NIC host-only

**Cài đặt**

- Update máy ảo

`apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y`

- Kế tiếp, chúng ta sẽ cài đặt KVM và 02 gói hỗ trợ

`apt-get install qemu-kvm libvirt-bin virtinst -y`

- Chuẩn bị cài OVS, chúng ta sẽ gỡ bridge libvirt mặc định (name: virbr0).

``` sh
virsh net-destroy default
virsh net-autostart --disable default
```

- Gán quyền cho user libvirtd và kvm

``` sh
sudo adduser `id -un` libvirtd
sudo adduser `id -un` kvm
```

- Vì chúng ta không sử dụng linux bridge mặc định, chúng ta có thể gỡ các gói ebtables bằng lệnh sau. (Không chắc chắn 100% là bước này cần thiết, nhưng hầu hết các bài hướng dẫn sẽ có bước này).

`aptitude purge ebtables -y`

- Chúng ta sẽ cài OVS bằng lệnh sau.

` apt-get install openvswitch-controller openvswitch-switch openvswitch-datapath-source -y`

- Các gói OVS được cài đặt xong, chúng ta sẽ check KVM bằng lệnh sau:

`virsh -c qemu:///system list`

Lệnh trên trả về danh sách các VM (máy ảo) đang chạy, lúc này sẽ trống.

- Kiểm tra lại OVS bằng lệnh sau:

``` sh
service openvswitch-switch status
ovs-vsctl show
```

- Đầu tiên, sẽ xử dụng lệnh ovs-vsctl để tạo bridge và add với 1 physical interface

``` sh
ovs-vsctl add-br br0
ovs-vsctl add-port br0 eth0
```

- Kiểm tra các bridge đã tạo và interface đã được gán hay chưa

``` sh
root@ubuntu:~#  ovs-vsctl show
8ff95bd9-d8c8-403e-bbc4-d584e25e7304
    Bridge "br0"
        Port "br0"
            Interface "br0"
                type: internal
        Port "eth0"
            Interface "eth0"
    ovs_version: "2.0.2"
```

- Chỉnh sửa file /etc/network/interfaces

``` sh
auto lo
iface lo inet loopback

auto eth0
iface eth0 inet manual
up ifconfig $IFACE 0.0.0.0 up
up ip link set $IFACE promisc on
down ip link set $IFACE promisc off
down ifconfig $IFACE down

auto eth1
iface eth0 inet static
address 10.10.10.50
netmask 255.255.255.0

auto br0
iface br0 inet static
address 192.168.100.44
netmask 255.255.255.0
gateway 192.168.100.1
network 192.168.100.0
broadcast 192.168.100.255
dns-nameservers 8.8.8.8 8.8.4.4
```

- Tiến hành reset lại network

`etc/init.d/networking restart`

- Như vậy ta đã cài xong kvm với OVS, để kiểm tra xem có các network nào trong KVM

`virsh net-list --all`

Lúc này có thể thấy network default đã bị hủy, ta cần tạo network mới để sử dụng. Tạo file `ovsnet.xml` cho libvirt network:

``` sh
<network>
   <name>br0</name>
   <forward mode='bridge'/>
   <bridge name='br0'/>
   <virtualport type='openvswitch'/>
 </network>
```

- Thực hiện lệnh để tạo network

``` sh
virsh net-define ovsnet.xml
 virsh net-start br0
 virsh net-autostart br0
```

- Kiểm tra lại network đã khai báo cho libvirt bằng lệnh `virsh net-list --all`, chúng ta sẽ nhìn thấy network có tên là `br0`, đây chính là network có type là `openvswitch` đã khai báo ở trên.

``` sh
root@ubuntu:~# virsh net-list --all
 Name                 State      Autostart     Persistent
----------------------------------------------------------
 br0                  active     yes           yes
 default              inactive   no            yes
```

Ở đây tạo nhanh một KVM guest sử dụng virt-install

``` sh
cd /var/lib/libvirt/images

wget https://ncu.dl.sourceforge.net/project/gns-3/Qemu%20Appliances/linux-microcore-3.8.2.img

virt-install \
      -n VM01 \
      -r 128 \
       --vcpus 1 \
      --os-variant=generic \
      --disk path=/var/lib/libvirt/images/linux-microcore-3.8.2.img,format=qcow2,bus=virtio,cache=none \
      --network network=br0 \
      --hvm --virt-type kvm \
      --vnc --noautoconsole \
      --import
```

## 6. Một vài câu lệnh với Open vSwitch

- ovs-<functionality> : Bạn chỉ cần nhập vào `ovs` rồi ấn `tab` 2 lần là có thể xem tất cả các câu lệnh đối với Open vSwitch.

- ovs-vsctl : là câu lệnh để cài đặt và thay đổi một số cấu hình ovs. Nó cung cấp interface cho phép người dùng tương tác với Database để truy vấn và thay đổi dữ liệu.
  - ovs-vsctl show: Hiển thị cấu hình hiện tại của switch.
  - ovs-vsctl list-br: Hiển thị tên của tất cả các bridges.
  - ovs-vsctl list-ports <bridge> : Hiển thị tên của tất cả các port trên bridge.
  - ovs-vsctl list interface <bridge>: Hiển thị tên của tất cả các interface trên bridge.
  - ovs-vsctl add-br <bridge> : Tạo bridge mới trong database.
  - ovs-vsctl add-port <bridge> : <interface> : Gán interface (card ảo hoặc card vật lý) vào Open vSwitch bridge.

- ovs-ofctl và ovs-dpctl : Dùng để quản lí và kiểm soát các  flow entries. OVS quản lý 2 loại flow:
  - OpenFlows : flow quản lí control plane
  - Datapath : là kernel flow.
  - ovs-ofctl giao tiếp với OpenFlow module, ovs-dpctl
giao tiếp với Kernel module.

- ovs-ofctl show <BRIDGE> : hiển thị thông tin ngắn gọn về switch bao gồm port number và port mapping.
- ovs-ofctl dump-flows <Bridge> : Dữ liệu trong OpenFlow tables
- ovs-dpctl show : Thông tin cơ bản về logical datapaths (các bridges) trên switch.
- ovs-dpctl dump-flows : Hiển thị flow cached trong datapath.
- ovs-appctl bridge/dumpflows <br> : thông tin trong flow tables và offers kết nối trực tiếp cho VMs trên cùng hosts.
- ovs-appctl fdb/show <br> : Hiển thị các cặp mac/vlan.


