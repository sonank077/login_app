# ProxyBytes iOS VPN Client (103.238.234.204:8080)

Ứng dụng iOS VPN 1-Chạm (1-Tap Connect) được thiết kế riêng để tự động định tuyến toàn bộ lưu lượng HTTP/HTTPS trên iPhone qua máy chủ **ProxyBytes Core Engine (103.238.234.204:8080)** và tích hợp sẵn chứng chỉ **ProxyBytes Root CA**.

---

## 🚀 Tính Năng Nổi Bật

* **1-Tap Connect:** Bật/Tắt VPN nhanh chóng chỉ với 1 nút bấm trung tâm.
* **Tích Hợp Sẵn Server:** Cấu hình trực tiếp IP `103.238.234.204:8080` (không cần nhập thủ công).
* **Đo Ping Thời Gian Thực:** Hiển thị độ trễ kết nối (Latency ms) tới VPS.
* **Tích Hợp Chứng Chỉ CA:** Nút bấm 1-chạm tự động mở Safari tải về hồ sơ chứng chỉ `ca.crt` và phím tắt mở Cài Đặt Tin Cậy (Certificate Trust Settings).
* **Hỗ Trợ Build IPA Tự Động:** Tích hợp sẵn workflow GitHub Actions, chỉ cần Push code lên GitHub là có ngay file `.ipa`.

---

## 🛠️ Hướng Dẫn Build IPA Trên GitHub Actions

1. **Khởi tạo và đẩy code lên GitHub:**
   ```bash
   git init
   git add .
   git commit -m "feat: Add ProxyBytes iOS VPN Client with GitHub Actions build"
   git branch -M main
   git remote add origin https://github.com/<USERNAME>/<REPO_NAME>.git
   git push -u origin main
   ```

2. **Tải file `.ipa` sau khi build:**
   * Truy cập vào kho lưu trữ GitHub của bạn.
   * Chọn tab **Actions** -> Chọn workflow **Build ProxyBytes iOS IPA** đang chạy.
   * Khi build hoàn tất (màu xanh lá), kéo xuống mục **Artifacts** để tải về **`ProxyBytesVPN-iOS.zip`** (bên trong chứa `ProxyBytesVPN.ipa`).

---

## 📱 Hướng Dẫn Cài Đặt Lên iPhone

File `.ipa` xuất ra dưới dạng unsigned (chưa ký), bạn có thể cài đặt dễ dàng qua các công cụ:

* **TrollStore (Khuyên dùng - iOS 14.0 - 16.6.1 / 17.0):**
  Chia sẻ trực tiếp file `ProxyBytesVPN.ipa` vào TrollStore -> Bấm **Install**. App sẽ chạy với full quyền NetworkExtension mà không bao giờ bị thu hồi (no revoke).
* **AltStore / Sideloadly:**
  Cắm cáp kết nối iPhone với máy tính -> Kéo file `ProxyBytesVPN.ipa` vào AltStore hoặc Sideloadly và nhập Apple ID để ký và cài đặt.
* **Esign / Scarlet / Gbox:**
  Nhập chứng chỉ doanh nghiệp (Enterprise Certificate) hoặc DNS vào Esign rồi ký và cài đặt trực tiếp trên iPhone.

---

## 🔐 Hướng Dẫn Bật Tin Cậy Chứng Chỉ CA (Bắt Buộc Lần Đầu)

1. Mở app **ProxyBytes VPN**.
2. Tại khung **CHỨNG CHỈ CA (SSL ROOT)**, bấm nút **"1. Tải Chứng Chỉ"**.
3. Safari mở ra hỏi *Trang web này đang cố gắng tải về hồ sơ cấu hình*, bấm **Cho phép** (Allow).
4. Vào **Cài đặt** (Settings) của iPhone -> Bấm vào mục **Đã tải về hồ sơ** (Profile Downloaded) ở trên cùng -> Chọn **Cài đặt** (Install).
5. Quay lại **Cài đặt chung** (General) -> **Giới thiệu** (About) -> Kéo xuống dưới cùng chọn **Cài đặt tin cậy chứng nhận** (Certificate Trust Settings).
6. Tại mục *Bật tin cậy đầy đủ cho các chứng nhận gốc*, gạt **BẬT** công tắc xanh cho **ProxyBytes Root CA**.
7. Quay lại app ProxyBytes VPN và bấm **CONNECT** để bắt đầu sử dụng!
