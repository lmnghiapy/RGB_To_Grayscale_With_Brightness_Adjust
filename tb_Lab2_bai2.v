`timescale 1ns / 1ps

module tb_image_to_grayscale;

    // --- 1. KHAI BÁO TÍN HIỆU ---
    reg        clk;
    reg        rst_n;
    
    // Input cho DUT
    reg [7:0]  r_in, g_in, b_in;
    reg        in_valid;
    reg [7:0]  brightness; // Tham số chỉnh sáng
    
    // Output từ DUT
    wire [7:0] gray_out;
    wire       out_valid;

    // Biến xử lý File
    integer    f_in;        // Con trỏ file đầu vào
    integer    f_out;       // Con trỏ file đầu ra
    integer    scan_status; // Kiểm tra đọc file
    
    // Biến tạm để đọc hex từ file (dùng 32-bit để an toàn, sau đó gán vào 8-bit)
    reg [31:0] r_tmp, g_tmp, b_tmp;

    // --- 2. KẾT NỐI MODULE (DUT) ---
    image_to_grayscale dut (
        .clk(clk),
        .rst_n(rst_n),
        .r_in(r_in),
        .g_in(g_in),
        .b_in(b_in),
        .in_valid(in_valid),
        .brightness(brightness),
        .gray_out(gray_out),
        .out_valid(out_valid)
    );

    // --- 3. TẠO XUNG CLOCK (100MHz) ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk; 
    end

    // --- 4. LUỒNG XỬ LÝ CHÍNH ---
    initial begin
        // A. Khởi tạo
        rst_n = 0;
        in_valid = 0;
        r_in = 0; g_in = 0; b_in = 0;
        
        // --- CẤU HÌNH ĐỘ SÁNG TẠI ĐÂY ---
        brightness = 8'd80; 
        // ---------------------------------

        // B. Mở file
        f_in  = $fopen("D:/Lab2/Lab2/Lab2_Bai2/baitap2_pic_input.txt", "r"); // File do Python tạo
        f_out = $fopen("D:/Lab2/Lab2/Lab2_Bai2/baitap2_pic_output.txt", "w"); // File để Python đọc lại

        if (f_in == 0) begin
            $display("LOI: Khong tim thay file 'input_hex.txt'. Hay chay Python truoc!");
            $finish;
        end

        // C. Reset hệ thống
        #20;
        rst_n = 1;
        #10;
        
        $display("--- BAT DAU XU LY ANH ---");

        // D. Vòng lặp đọc từng dòng Hex
        // %h dùng để đọc dữ liệu dạng Hex (vd: FF A0 12)
        while (!$feof(f_in)) begin
            scan_status = $fscanf(f_in, "%h %h %h\n", r_tmp, g_tmp, b_tmp);
            
            if (scan_status == 3) begin
                @(posedge clk);
                r_in     = r_tmp[7:0];
                g_in     = g_tmp[7:0];
                b_in     = b_tmp[7:0];
                in_valid = 1'b1;
            end else begin
                in_valid = 1'b0; // Dòng trống hoặc lỗi
            end
        end

        // E. Kết thúc đọc
        @(posedge clk);
        in_valid = 1'b0;
        $fclose(f_in);

        // Đợi một chút để pipeline xả hết dữ liệu cuối cùng
        #400; 
        $fclose(f_out);
        $display("--- DA XONG. KIEM TRA FILE 'baitap2_pic_output.txt' ---");
        $finish;
    end

    // --- 5. GHI KẾT QUẢ RA FILE ---
    // Bất cứ khi nào DUT báo out_valid, ghi giá trị Hex vào file
    always @(posedge clk) begin
        if (out_valid) begin
            // Ghi ra file dạng Hex 2 chữ số (vd: a5)
            $fwrite(f_out, "%02h\n", gray_out);
        end
    end

endmodule 