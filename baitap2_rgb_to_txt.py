from PIL import Image
import numpy as np

img = Image.open("baitap2_anhgoc.jpg").convert("RGB")
pixels = [(r,g,b) for r,g,b in np.array(img).reshape(-1, 3)]

with open("baitap2_pic_input.txt", "w") as f:
    for r, g, b in pixels:
        # %02x đảm bảo mỗi kênh luôn 2 chữ số: 0 → "00", 255 → "ff"
        f.write(f"{r:02x} {g:02x} {b:02x}\n")

print(f"Tong so pixel: {len(pixels)}")
print(f"Kich thuoc anh: {img.size}")  # (width, height)