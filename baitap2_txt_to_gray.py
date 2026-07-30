import cv2
import numpy as np
from PIL import Image

# ============================================================
# CẤU HÌNH — chỉnh tại đây
# ============================================================
INPUT_HEX_FILE = "baitap2_pic_output.txt"   # file output từ testbench
OUTPUT_IMAGE   = "baitap2_grayscale.jpg"      # tên file ảnh sẽ tạo
IMG_WIDTH      = 2048                        # chiều rộng ảnh gốc (pixel)
IMG_HEIGHT     = 1365                        # chiều cao  ảnh gốc (pixel)
# ============================================================

def hex_to_grayscale(hex_file, out_image, width, height):
    # 1. Đọc toàn bộ giá trị grayscale từ file
    gray_values = []
    with open(hex_file, "r") as f:
        for line_no, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue  # bỏ dòng trống
            try:
                val = int(line, 16)   # chuyển hex → int
                if val < 0 or val > 255:
                    raise ValueError(f"Gia tri {val} vuot ngoai [0, 255]")
                gray_values.append(val)
            except ValueError as e:
                print(f"  [CANH BAO] Dong {line_no}: '{line}' — {e}, bo qua.")

    total_pixels = width * height
    print(f"Doc duoc   : {len(gray_values)} gia tri")
    print(f"Can thiet  : {total_pixels} pixels ({width}x{height})")

    # 2. Kiểm tra số lượng
    if len(gray_values) < total_pixels:
        print(f"[LOI] Khong du pixel! Con thieu {total_pixels - len(gray_values)}.")
        return
    if len(gray_values) > total_pixels:
        print(f"[CANH BAO] Du thua {len(gray_values) - total_pixels} gia tri — cat bo phan cuoi.")
        gray_values = gray_values[:total_pixels]

    # 3. Tạo ảnh grayscale từ danh sách pixel
    img = Image.new("L", (width, height))   # mode "L" = 8-bit grayscale
    img.putdata(gray_values)

    # 4. Lưu file
    img.save(out_image)
    print(f"Da luu anh : {out_image}")

if __name__ == "__main__":
    hex_to_grayscale(INPUT_HEX_FILE, OUTPUT_IMAGE, IMG_WIDTH, IMG_HEIGHT)