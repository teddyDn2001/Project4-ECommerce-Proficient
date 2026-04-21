# Phân Tích Dữ Liệu Phim TMDB

Dự án phân tích dữ liệu phim từ dataset TMDB sử dụng bash script, thực hiện các phân tích thống kê và hiển thị kết quả trực tiếp trên terminal.

## 📋 Mô tả

Script bash tự động tải và phân tích dữ liệu phim từ dataset TMDB, thực hiện các tác vụ phân tích cơ bản và nâng cao, hiển thị kết quả trực tiếp trên terminal mà không cần tạo file output.

## ✨ Tính năng

- ✅ Tự động tải dữ liệu từ GitHub
- ✅ Sắp xếp phim theo ngày phát hành
- ✅ Lọc phim theo điểm đánh giá
- ✅ Tìm phim có doanh thu cao/thấp nhất
- ✅ Tính tổng doanh thu
- ✅ Top 10 phim lợi nhuận cao nhất
- ✅ Tìm đạo diễn và diễn viên có nhiều phim nhất
- ✅ Thống kê số lượng phim theo thể loại

## 🛠️ Yêu cầu hệ thống

- **Hệ điều hành:** Linux hoặc macOS
- **Shell:** Bash
- **Công cụ cần thiết:**
  - `curl` - Tải dữ liệu từ internet
  - `awk` - Xử lý và phân tích dữ liệu
  - `sort` - Sắp xếp dữ liệu
  - `head`, `tail` - Xử lý file

## 🚀 Cài đặt và sử dụng

### Bước 1: Clone repository

```bash
git clone <repository-url>
cd Project1
```

### Bước 2: Cấp quyền thực thi

```bash
chmod +x analyze_movies.sh
```

### Bước 3: Chạy script

```bash
./analyze_movies.sh
```

## 📊 Kết quả phân tích

Script sẽ hiển thị các thông tin sau:

1. **Sắp xếp phim theo ngày phát hành**
   - Tổng số phim trong dataset
   - Top 5 phim mới nhất

2. **Phim đánh giá > 7.5**
   - Số lượng phim có đánh giá trên 7.5
   - Top 5 phim đánh giá cao nhất

3. **Doanh thu cao/thấp nhất**
   - Phim có doanh thu cao nhất
   - Phim có doanh thu thấp nhất

4. **Tổng doanh thu**
   - Tổng doanh thu của tất cả phim trong dataset

5. **Top 10 lợi nhuận**
   - 10 phim có lợi nhuận cao nhất (Doanh thu - Ngân sách)

6. **Đạo diễn và diễn viên**
   - Đạo diễn có nhiều phim nhất
   - Diễn viên có nhiều phim nhất

7. **Thống kê thể loại**
   - Top 10 thể loại phim phổ biến nhất

## 📁 Cấu trúc dự án

```
Project1/
├── analyze_movies.sh    # Script phân tích chính
├── HUONG_DAN.md         # Hướng dẫn sử dụng (tiếng Việt)
├── README.md            # File này
└── tmdb-movies.csv      # File dữ liệu (tự động tải)
```

## 🔧 Công nghệ sử dụng

- **Bash Scripting** - Ngôn ngữ chính
- **AWK** - Xử lý và phân tích dữ liệu CSV
- **Linux/Unix Tools** - `curl`, `sort`, `head`, `tail`

## 📝 Giải thích kỹ thuật

### Cách script hoạt động

1. **Tải dữ liệu:** Sử dụng `curl` để tải file CSV từ GitHub
2. **Xác định cột:** Tự động tìm vị trí các cột cần thiết trong header
3. **Xử lý dữ liệu:** Sử dụng `awk` để xử lý và tính toán
4. **Sắp xếp:** Sử dụng `sort` để sắp xếp kết quả
5. **Hiển thị:** In kết quả trực tiếp ra terminal

### Các lệnh chính

- `awk`: Xử lý và tính toán trên dữ liệu CSV
- `sort`: Sắp xếp dữ liệu theo các tiêu chí khác nhau
- `head/tail`: Lấy phần đầu/cuối của file
- `curl`: Tải file từ internet

## 🐛 Xử lý lỗi

### Lỗi tải dữ liệu
```bash
# Kiểm tra kết nối internet
ping -c 3 google.com

# Thử tải thủ công
curl -k -o tmdb-movies.csv "https://raw.githubusercontent.com/yinghaoz1/tmdb-movie-dataset-analysis/master/tmdb-movies.csv"
```

### Lỗi quyền thực thi
```bash
chmod +x analyze_movies.sh
```

### Lỗi không tìm thấy công cụ
```bash
# Kiểm tra các công cụ có sẵn
which curl awk sort head tail
```

## 📄 License

Dự án này được tạo cho mục đích học tập và nghiên cứu.

## 👥 Tác giả

Data Engineer Team

## 🙏 Cảm ơn

- Dataset được lấy từ: [TMDB Movie Dataset](https://github.com/yinghaoz1/tmdb-movie-dataset-analysis)
- Cộng đồng open source

---

**Lưu ý:** Script chỉ hiển thị kết quả trên terminal, không tạo file output. Nếu cần lưu kết quả, bạn có thể sử dụng output redirection: `./analyze_movies.sh > results.txt`
