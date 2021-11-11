Fernet Token
Là loại token mới nhất của keystone khắc phục được tất cả các nhược điểm của 2 loại token trên, nó mang vừa đủ thông tin cần thiết trên token và đồng thời cũng cho phép các Service có thể cache các token giải quyết vấn đề tắc nghẽn cổ chai của UUID token, Fernet Token sử dụng Hệ mật mã khóa đối xứng tức là key mã hóa cũng chính là key giải mã. Nhưng trong môi trường Production việc sử dụng lâu dài 1 khóa là một mối nguy hại tiềm tàng cho hệ thống chính vì vậy Fernet token mang trong nó một cơ chế xoay vòng khóa để đảm bảo khóa chỉ tồn tại trong một khoảng thời gian nhất định mà vẫn giải mã token được trước thời gian token hết hạn. Có 3 loại khóa được sử dụng trong Fernet Token (nhưng vẫn dựa trên hệ mật khóa đối xứng)

Loại 1 - Primary Key: sử dụng cho cả 2 mục đích mã hóa và giải mã fernet tokens. Các key được đặt tên theo số nguyên bắt đầu từ 0. Trong đó Primary Key có chỉ số cao nhất.

Loại 2 - Secondary Key: chỉ dùng để giải mã. -> Lowest Index < Secondary Key Index < Highest Index

Loại 3 - Stagged Key: - tương tự như secondary key trong trường hợp nó sử dụng để giải mã token. Tuy nhiên nó sẽ trở thành Primary Key trong lần luân chuyển khóa tiếp theo. Stagged Key có chỉ số 0

Quá trình xoay vòng khóa được mô tả như sau.

![image](https://user-images.githubusercontent.com/44855268/141074882-9fa421a5-12c9-4b6f-921d-d0245b696fec.png)

## Setup số lượng key

Khi sử dụng fernet tokens yêu cầu chú ý về thời hạn của token và vòng đời của khóa. Vấn đề nảy sinh khi secondary keys bị remove khỏi key repos trong khi vẫn cần dùng key đó để giải mã một token chưa hết hạn (token này được mã hóa bởi key đã bị remove).
Để giải quyết vấn đề này, trước hết cần lên kế hoạch xoay khóa. Ví dụ bạn muốn token hợp lệ trong vòng 24 giờ và muốn xoay khóa cứ mỗi 6 giờ. Như vậy để giữ 1 key tồn tại trong 24h cho mục đích decrypt thì cần thiết lập max_active_keys=6 trong file keytone.conf (do tính thêm 2 key đặc biệt là primary key và staged key ). Điều này giúp cho việc giữ tất cả các key cần thiết nhằm mục đích xác thực token mà vẫn giới hạn được số lượng key trong key repos (/etc/keystone/fernet-keys/).

token_expiration = 24

rotation_frequency = 6

max_active_keys = (token_expiration / rotation_frequency) + 2

## Quá trình sinh Fernet Token
Giống như các loại token User phải gửi các thông tin định danh và xác thực để Keystone xác thức và cấp Token. Fernet token sử dụng hệ mã khóa đối xứng để ký và giải mã nên ta có thể thấy trong hình các thông tin của token được ký để tạo ra một Cipher Text ( Bản mã) kết hợp với HMAC để đảm bảo tính toàn vẹn và bí mật cho Token.

## Quá trình validate Fernet Token
Quá trình validate Fernet token cũng tương tự như các Token khác chỉ có một vài điểm khác ở giai đoạn đầu của quá trình validate service sẽ sử dụng khóa đối xứng để giải mã và lấy ra các thông tin của token như Current Time, Expiry Time ... để xác minh tính hợp lệ cuả Token.

## Quá trình thu hồi
Quá trình thu hồi hoàn toàn tương tự như các loại token khác.

Trước khi thu hồi Fernet Token Keystone cần thực hiện bước Validate Token, khi Token được xác minh tính hợp lệ, keystone sẽ khởi tạo sự kiện thu hồi token và Update các thông tin cần thiết (User ID, Project ID, Rovoke At ...) vào bảng Revoke trong Database của keystone.
