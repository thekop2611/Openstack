![image](https://user-images.githubusercontent.com/44855268/138988462-2ae05322-fe8b-4497-b463-0c42ee9854ad.png)

1. Khi user đăng nhập vào hệ thống, dashboard hoặc CLI sẽ gửi thông tin đăng nhập đến keystone để xác thực.
2. Keystone xác nhận thông tin để authen là hợp lệ và sẽ gửi lại token để xác thực khi user tương tác với các thành phần khác của hệ thống.
3. Dashboard/CLI gửi request tạo VM mới tới nova-api
4. nova-api gửi thông tin token nhận được tới keystone để xác nhận và chop phép thực hiện thao tác
5. Keystone xác nhận token và trả về cho phép thực hiện request
6. nova-api gửi thông tin đến nova-db
7. Tạo bản ghi thông tin về VM trong DB và trả về kết quả cho nova-api
8. nova-api gửi đưa thông tin tạo VM vào hàng đợi để create
9. nova-scheduler lấy thông tin VM từ hàng đợi
10.nova-scheduler giao tiếp với DB để tính toán host để tạo VM dựa trên thông tin về VM cần tạo và tài nguyên còn lại của các host
11.DB trả kết quả về cho nova-scheduler sau khi tính toán.
12.nova-scheduler gửi thông tin vừa nhận được đến hàng đợi
13.nova-compute lấy request từ hàng đợi với các thông tin về VM và host để đặt VM
14.nova-compute gửi thông tin cấu hình VM và host qua hàng đợi
15.nova-conductor nhận thông tin từ nova-compute thông qua hàng đợi.
16.nova-conductor giao tiếp với DB để kiểm tra thông tin
17.nova-conductor nhận về thông tin về VM
18.nova-conductor trả kết quả lại cho nova-compute thông qua hàng đợi.
19.nova-compute gửi request kèm thông tin image cho glance-api kèm theo token để glance-api xác nhận với keystone
20.glance-api xác nhận token với keystone.
21.glance-api trả kết quả thông tin về image được lấy từ glance storage cho nova-compute.
22.nova-compute gửi request kèm theo token cho network API để xác nhận với keystone và lấy thông tin về IP cho VM được tạo
23.NetworkAPI xác nhận token với keystone
24.NetworkAPI gửi lại thông tin IP cho nova-compute
25.nova-compute gửi request kèm theo token cho cinder để xác nhận với keystone và lấy thông tin về volume cho VM.
26.cinder xác nhận token với keystone
27.cinder gửi thông tin về volume cho nova-compute
28.nova-compute gửi toàn bộ thông tin hoàn thiện cho hypervisor để tiến hành request tạo máy ảo.
