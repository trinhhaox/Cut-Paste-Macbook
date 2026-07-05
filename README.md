# CutPaste

**True Cut & Paste for macOS Finder.**

macOS Finder chỉ hỗ trợ Copy (⌘C) + Paste (⌘V). CutPaste bổ sung tính năng **Cut (⌘X)** để di chuyển file nhanh chóng — giống như Windows Explorer.

## Tính năng

- **⌘X** — Cut file/folder đang chọn trong Finder
- **⌘V** — Paste (di chuyển) file đến thư mục hiện tại
- **⌘C** — Copy bình thường (tự động hủy cut nếu có)
- **⌘Z** — Hoàn tác lần paste gần nhất (trả file về vị trí cũ), hoặc dùng menu **Hoàn tác di chuyển**
- **Không chiếm phím khi đang đổi tên file** — ⌘X/⌘C/⌘V/⌘Z hoạt động bình thường trong ô sửa tên
- **Thông báo dạng banner + âm thanh** khi cut / paste / hoàn tác (thay cho popup chặn màn hình)
- Thư mục đích bám theo cửa sổ Finder đang thao tác (dùng *insertion location*) — chính xác kể cả khi mở nhiều cửa sổ
- Hiển thị icon trên menu bar với số file đang chờ paste
- Tự động xử lý trùng tên file
- Giao diện song ngữ **Tiếng Việt / English** — tự chọn trong menu **Ngôn ngữ** (Theo hệ thống / English / Tiếng Việt), đổi ngay không cần khởi động lại
- Hỗ trợ khởi động cùng macOS
- Universal Binary — chạy trên cả Apple Silicon và Intel Mac

## Cài đặt

### Tải DMG (Khuyến nghị)

1. Tải file `.dmg` từ [Releases](../../releases)
2. Mở DMG, kéo **CutPaste** vào thư mục **Applications**
3. Mở app, cấp quyền **Accessibility** khi được hỏi

### Build từ source

```bash
git clone https://github.com/trinhhao/CutPaste.git
cd CutPaste
bash Scripts/build.sh
cp -r build/CutPaste.app /Applications/
```

## Cấp quyền Accessibility

App cần quyền Accessibility để hoạt động:

1. Mở **System Settings** → **Privacy & Security** → **Accessibility**
2. Nhấn **+**, thêm **CutPaste**
3. Bật toggle

### Nếu vẫn chưa hoạt động

Trên một số phiên bản macOS, bạn cần bật thêm:

- **Privacy & Security → Input Monitoring** (CutPaste)
- **Privacy & Security → Automation** → cho phép **CutPaste** điều khiển **Finder**

App cũng sẽ hỏi quyền **Notifications** để hiển thị banner khi cut/paste — không bắt buộc, nếu từ chối app vẫn hoạt động bình thường (chỉ báo lỗi bằng popup khi cần).

Sau khi bật quyền, hãy **Thoát CutPaste và mở lại**.

Nếu bạn **build lại** hoặc **di chuyển app sang đường dẫn khác**, macOS có thể yêu cầu cấp quyền lại. Khi đó hãy tắt/bật lại CutPaste trong các mục quyền ở trên.

### Sau khi cập nhật phiên bản mới, ⌘X/⌘V không hoạt động?

Đây là do macOS còn lưu quyền của bản cũ (chữ ký app thay đổi giữa các bản build). Toggle Accessibility vẫn hiện BẬT nhưng thực tế đã vô hiệu. Khắc phục:

```bash
tccutil reset Accessibility com.antigravity.cutpaste
tccutil reset AppleEvents com.antigravity.cutpaste
```

Sau đó mở lại CutPaste và cấp quyền Accessibility khi được hỏi.

### Cảnh báo "Apple không thể xác minh..."

App chưa được notarize bởi Apple (chưa có Developer ID). Cách mở:

- **System Settings → Privacy & Security** → kéo xuống cuối → nhấn **Open Anyway**, hoặc
- Chạy: `xattr -dr com.apple.quarantine /Applications/CutPaste.app`

## Yêu cầu hệ thống

- macOS 13.0 (Ventura) trở lên
- Apple Silicon hoặc Intel Mac

## License

MIT License
