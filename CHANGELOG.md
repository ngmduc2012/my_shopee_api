## 0.1.0-beta.1

- Bản thử nghiệm công khai đầu tiên; chưa xác minh bằng credential Shopee thật/CORS.
- Repository, issue tracker và CI độc lập cho cộng đồng.
- Client Dart độc lập, dùng được từ Flutter và Dart server/CLI.
- Ký SHA256 theo Shopee Affiliate Open API; hỗ trợ GraphQL tùy chỉnh.
- Product offers, phân trang, tìm theo shop/item và tạo short link.
- Đọc link sản phẩm Việt Nam; theo HTTP redirect có giới hạn cho short link.
- Phân biệt lỗi HTTP, GraphQL, timeout, transport và response không hợp lệ.
- Có ví dụ offline, test, tài liệu giới hạn web và hướng dẫn publish.
- Dùng json_annotation 4.9 và codegen 6.9 để tích hợp với DS My Peace hiện tại; runtime SDK vẫn độc lập Firebase/UI.
