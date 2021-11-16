# Tổng quan về Federated authentification
## Tại sao nên dùng Federated authentification
  - Mỗi 1 định danh mới được tạo ra làm tăng nguy cơ về bảo mật
  - Tránh được các rắc rối do quá nhiều account để nhớ và đăng nhập
  - Giúp việc quản lý multi cloud dễ dàng hơn
## Ưu nhược điểm
### Ưu điểm:
  - Tận dụng các tiện ích sẵn có để xác thực và lấy thông tin người dùng
  - Tách biệt chức năng định danh khỏi keystone
  - Tiền đề để xây dựng hệ thống xác thực tập trung SSO và hybrid/multi cloud
### Nhược điểm:
  - Việc triển khai phức tạp hơn so với các phương pháp xác thực khác
## Khái niệm Identity Provider
  - IP là dịch vụ nhận các thông tin đăng nhập, xác thực và gửi lại response dưới dạng Y/N, response này sẽ chứa một số thông tin khác như tên người dùng, tên hiển thị cũng như user role
  - IP được hiểu là các phần mềm dựa trên LDAP, AD, MongoDB hoặc các hệ thống định danh của Facebook, Twitter, Google, v.v.
## 2 mô hình phổ biến
### Mô hình 1: Keystone as a service provider
  - Sử dụng 1 IP ngoài như là 1 nguồn định danh và xác thực
### Mô hình 2: Keystone to keystone
  - 2 keystone được kết nối với nhau và 1 trong số đó hoạt động như 1 IP
## Mô hình hoạt động với SAML2.0 WebSSO
  - SAML là một chuẩn mở cho phép IP xác thực người dùng và ủy quyền cho người dùng sử dụng dịch vụ của SP mà không bắt buộc người dùng phải tạo tài khoản đăng nhập vào dịch vụ đó
  - SAML tự động giải quyết được 2 vấn đề là xác thực và ủy quyền
### Cách hoạt động của SAML

![image](https://user-images.githubusercontent.com/44855268/142021240-203d5602-8d40-48ba-95da-bd176978e84c.png)

  - Bước 1: User đăng nhập dịch vụ của SP
  - Bước 2: SP tạo ra SAML request gửi đến IP, request này được SP gắn sign bằng secret key của SP
  - Bước 3: IP nhận được request từ SP và dùng public key của SP để xác thực request được gửi từ đúng SP
  - Bước 4: Sau khi xác thực được sign của SP, IP sẽ lấy thông tin người dùng đăng nhập để redirect về cho SP sử dụng (SAML response) và response này được gắn sign bằng secret key của IP, đồng thời các kết quả dữ liệu trả về cũng được mã hóa bằng public key của SP
  - Bước 5: Khi SP nhận được SAML response, SP sẽ dùng public key của IP để xác nhận bản tin response được gửi từ đúng IP. Sau khi xác nhận, SP tiếp tục dùng public key của mình để giải mã các thông tin kết quả dữ liệu gắn kèm để giải mã, lấy thông tin dữ liệu người dùng và đăng nhập vào hệ thống
### Các loại key trong quá trình xác thực
  - Trước khi thực hiện quá trình xác thực, SP và IP phải trao đổi public key với nhau trước. Thông thường, SP và IP đều có 1 public URL chứa metadata, metadata này chứa các thông tin công khai như public key, URL điều hướng khi có request đến
  - Trong trường hợp hệ thống của IP đã có sẵn và không lấy public key của SP thông qua metadata URL được thì SP phải gửi public key cho IP trước khi thực hiện xác thực
### Hoạt động của SAML trong Openstack

  ![image](https://user-images.githubusercontent.com/44855268/142022001-4868ac28-f538-4aa6-9d0f-532e4f4e2294.png)

