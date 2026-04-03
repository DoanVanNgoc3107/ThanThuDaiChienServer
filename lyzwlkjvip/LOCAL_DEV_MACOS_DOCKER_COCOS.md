# Tài liệu triển khai local dev (macOS + OrbStack + Cocos2d-x)

## 1) Mục tiêu
- Dựng môi trường dev backend game trên macOS bằng Docker (OrbStack), ưu tiên chạy trong LAN IP.
- Kiểm tra tiến độ đang chạy tới đâu, sửa lỗi ngay tại bước lỗi, rồi chạy tiếp.
- Chuẩn bị quy trình chạy client Cocos2d-x trên macOS để dev UI trước khi build mobile.

---

## 2) Kết quả phân tích dự án

## 2.1 Backend (`服务端/lyzwlkjvip`)
- Stack legacy, trọng tâm Python 2.7 + Supervisor + nhiều tiến trình game.
- Các thành phần phụ trợ cần có: MySQL 5.6, Redis 6.2, MongoDB 4.4, NSQ, PHP/Nginx (GM/patch).
- Tài liệu gốc `huongdan.txt` viết cho Linux/CentOS (`yum`, đường dẫn tuyệt đối `/mnt`, `/www`), nên khi chạy trên macOS cần lớp tương thích path/runtime.

## 2.2 Client (`源码/MyLuaGame`)
Theo `项目结构详细文档.md` + `项目结构说明.md`:
- Client Lua + Cocos2d-x, kiến trúc MVC rõ ràng.
- Điểm vào chính: `src/main.lua`, `src/app/game_app.lua`.
- Module UI quan trọng để dev nhanh:
  - Login: `src/app/views/login/*`
  - City UI: `src/app/views/city/view.lua` và nhánh `city/*`
  - Contract module: `src/app/views/city/develop/contract/*`
- Dự án/nhánh nghiệp vụ này phụ thuộc Python 2.7 (tài liệu cũng xác nhận).

---

## 3) Trạng thái triển khai hiện tại (đã kiểm tra thực tế)

## 3.1 Docker OrbStack
File đang dùng: `docker-compose.local.yml`

Services **đang UP**:
- `pokemon-mysql56` (3306)
- `pokemon-redis62` (6379)
- `pokemon-mongo44` (27017)
- `pokemon-php56-nginx` (81)
- `pokemon-nsqlookupd` (4160/4161)
- `pokemon-nsqd` (4150/4151)
- `pokemon-nsqadmin` (4171)

=> Tức là phần "hạ tầng nền" trong Docker đã chạy được.

## 3.2 Python 2.7 trên macOS
Đã cài và xác nhận:
- `pyenv` có `2.7.18`
- `.python-version` của project đang là `2.7.18`
- `python --version` => `Python 2.7.18`
- Các package cốt lõi đã cài thành công: `msgpack-python`, `tornado`, `supervisor`, `pymongo`, `psutil`

Lưu ý:
- `cryptography==2.6`/`pyOpenSSL` bị lỗi build do header OpenSSL trên macOS (không chặn bước bring-up cơ bản hiện tại).

## 3.3 Supervisor game stack
Đã xác minh: có dấu vết đã từng start supervisor, nhưng các process game hiện chưa chạy được đầy đủ vì mismatch môi trường Linux->macOS:
- Thiếu/không thực thi được binary trong `release/bin/*` (các ini dạng `command=.../release/bin/...` báo *file is not executable*).
- Nhiều command hardcode đường dẫn tuyệt đối Linux như `/mnt/...`, `/www/...` (trên macOS chưa map đúng nên báo *no such file*).
- `mongod` trong supervisor trỏ config Linux cũ (`/www/server/mongodb/config.conf`).

Kết luận hiện trạng:
- **Base services Docker: OK**
- **Full stack game qua supervisor local macOS: chưa đạt**, cần thêm lớp tương thích path + binary Linux chuẩn.

---

## 4) LAN IP dev
Đã lấy được LAN IP máy hiện tại:
- `192.168.1.11`

Có thể dùng các endpoint:
- GM web: `http://192.168.1.11:81/gm/gm.php`
- Player web: `http://192.168.1.11:81/gm`
- NSQ Admin: `http://192.168.1.11:4171`

Kiểm tra IP hardcode `192.168.1.11` trong project backend hiện không còn kết quả match (đã được thay/không còn trong cây code hiện tại).

---

## 5) Quy trình tiếp tục để chạy full game server đúng chuẩn

Do tài liệu gốc là Linux tuyệt đối, để chạy full ổn định trên máy macOS hiện tại nên đi 1 trong 2 hướng:

## Hướng A (khuyến nghị): Chạy runtime game chính trong Linux container riêng
1. Tạo container runtime Linux cho `mnt/pokemon/release` (đúng Python2 + deps + supervisor).
2. Bind mount project vào đúng đường dẫn Linux kỳ vọng (`/mnt`, `/www`).
3. Chạy `supervisord -c /mnt/pokemon/deploy_dev/supervisord.conf` trong container đó.
4. Start theo nhóm service, sửa lỗi tới đâu chạy lại tới đó.

## Hướng B: Chạy trực tiếp host macOS
1. Tạo symlink map đúng tuyệt đối:
   - `/mnt -> /Volumes/SSD/.../服务端/lyzwlkjvip/mnt`
   - `/www -> /Volumes/SSD/.../服务端/lyzwlkjvip/www`
2. Cấp quyền execute cho toàn bộ binary cần thiết trong `mnt/pokemon/release/bin/*`.
3. Chỉnh lại các ini lỗi path/mongod nếu cần.
4. Start lại supervisor.

> Hướng B nhanh nhưng rủi ro cao vì phụ thuộc host setup và quyền `sudo`.

---

## 6) Checklist xử lý lỗi theo đúng yêu cầu “fail đâu sửa đó”
1. Chạy 1 bước.
2. Nếu fail: chụp đúng log của bước đó.
3. Sửa đúng nhóm lỗi (path, quyền execute, dep Python2, binary thiếu, config Mongo/NSQ...).
4. Chạy lại đúng bước vừa fail.
5. Pass mới sang bước kế tiếp.

---

## 7) Phần Client Cocos2d-x trên macOS (dev UI trước mobile)

## 7.1 Mục tiêu
- Dùng bản macOS build để iterate giao diện nhanh, không phải build IPA/APK liên tục.

## 7.2 Chuẩn bị công cụ
- Cài Xcode (bạn đã nói sẽ tải trước).
- Cài Command Line Tools:
  - `xcode-select --install`
- Cài build tools:
  - `brew install cmake ninja`

## 7.3 Chạy client để dev UI
1. Mở project Cocos trong `源码/MyLuaGame`.
2. Build target macOS Debug.
3. Đảm bảo config patch/version của client trỏ về LAN IP backend (`192.168.1.11`) thay vì IP public cũ.
4. Ưu tiên test các flow UI:
   - Login -> chọn server
   - Vào city main view
   - Contract UI (`city/develop/contract`)

## 7.4 Lưu ý kỹ thuật Cocos/Lua
- Giữ đồng bộ version engine Cocos2d-x với bản dự án gốc.
- Nếu có native bridge/SDK mobile-only, bọc điều kiện compile để macOS build được.
- Tối ưu vòng lặp UI bằng hot update resource/script thay vì full rebuild.

---

## 8) Trạng thái cuối cùng của phiên triển khai này (đã cập nhật mới nhất)
- [x] Đã phân tích theo `huongdan.txt` + tài liệu `MyLuaGame`.
- [x] Đã kiểm tra tiến độ Docker hiện có và xác nhận service nào đang chạy.
- [x] Đã cài và xác nhận Python 2.7.18 trên máy host.
- [x] Đã dựng thêm `game-runtime` (CentOS 7) trong `docker-compose.local.yml` để chạy supervisor đúng chuẩn Linux path (`/mnt`, `/www`).
- [x] Đã fix yum CentOS 7 về vault + cài được Python2/pip/supervisor trong container runtime.
- [x] Đã cài thêm dependency runtime quan trọng trong container: `M2Crypto`, `fabric`, `luajit`, `lz4`, `psutil`, `numpy`, `pycrypto/pycryptodome`.
- [x] Đã start được `supervisord` trong container runtime.
- [x] Đã start được nhóm NSQ trong supervisor sau khi cấp quyền execute binary (`nsqlookupd`, `nsqd`, `nsqadmin`).
- [x] Đã fix `payment_server` lên RUNNING (đã hết lỗi `M2Crypto`).
- [x] Đã fix `anti_cheat_server` lên RUNNING (đã có `luajit`).
- [x] Đã fix `gm_server` lên RUNNING (đã có `fabric` và Mongo bridge).
- [x] Đã fix các storage/account/comment/crossdb service lên RUNNING sau khi bridge Mongo (`127.0.0.1:27017 -> pokemon-mongo44:27017`).
- [x] `online_fight_forward_server` đã RUNNING sau khi đổi `query_ip_url` sang `http://127.0.0.1:18081/ip` và cấp quyền execute cho `online_fight_forward/agent`.
- [x] Đã bổ sung shim module `tgasdk.sdk` nội bộ để vượt qua lỗi thiếu SDK analytics.
- [x] `game_server1`/`game_server2` đã RUNNING sau khi cài thêm `rpdb` (Python2).
- [x] Toàn bộ service game chính trong supervisor đã RUNNING ổn định.
- [ ] `mongod` trong supervisor vẫn để `STOPPED` có chủ đích (đang dùng Mongo container `pokemon-mongo44` thay thế).

---

## 9) Lệnh kiểm tra nhanh bạn có thể chạy lại bất cứ lúc nào
```bash
cd "/Volumes/SSD/Kumacenter_口袋新世纪/服务端/lyzwlkjvip"

docker compose -f docker-compose.local.yml ps

docker compose -f docker-compose.local.yml logs --tail=100 php56

docker compose -f docker-compose.local.yml logs --tail=100 mongo44

docker compose -f docker-compose.local.yml logs --tail=100 mysql56
```
