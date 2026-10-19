# Kiểm HTTP local

Mock tự viết từ contract chính thức liên kết trong README package; fixture giả,
không phải dữ liệu trả về từ Shopee thật. Không tìm được mock của owner vì Postman
CLI chưa đăng nhập. Không đăng nhập/push/deploy để chạy kiểm tra này.

```sh
postman simulation run postman/simulations/shopee.sim.yaml --port 4908 --output ndjson
```

Terminal khác, cùng thư mục package:

```sh
fvm dart run example/my_shopee_api_example.dart http://127.0.0.1:4908/shopee/graphql
```

Client HTTP thật đi qua success, tạo short link, GraphQL rate limit, HTTP 503,
JSON không hợp lệ và timeout. Kiểm log `request` của simulation để xác nhận caller
đã đến mock. Mock này không chứng minh quyền API, CORS hay schema Shopee đang chạy.
Ví dụ chữ ký chính thức được kiểm độc lập bằng unit test.

Mock trả 501 cho operation chưa được mô hình hóa. Không gửi credential thật vào
mock hoặc lưu log vào Git. Dừng đúng simulation của lượt kiểm này:

```sh
pkill -INT -f 'simulation run postman/simulations/shopee.sim.yaml'
```
