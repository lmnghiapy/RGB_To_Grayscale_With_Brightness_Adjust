module image_to_grayscale (clk,rst_n,r_in,g_in,b_in,in_valid,gray_out,out_valid,brightness);
    input clk,rst_n;      
    input [7:0]r_in,g_in,b_in;       
    input  in_valid;   
    output reg [7:0]gray_out;   
    output reg out_valid;  
	 input  wire [7:0]  brightness;

    
    wire [15:0] r_mul = r_in * 8'd77;   // 0.299 * 256 ≈ 77
    wire [15:0] g_mul = g_in * 8'd150;  // 0.587 * 256 ≈ 150
    wire [15:0] b_mul = b_in * 8'd29;   // 0.114 * 256 ≈ 29

    wire [17:0] acc = {2'b00, r_mul} + {2'b00, g_mul} + {2'b00, b_mul};
    wire [17:0] acc_rounded = acc + 18'd128;
    wire [7:0] gray_base = acc_rounded[17:10];
	 // --- THÊM LOGIC CHỈNH ĐỘ SÁNG ---
    // Mở rộng lên 9 bit hoặc 10 bit để phát hiện tràn số khi cộng brightness
    wire [9:0] gray_bright = {2'b00, gray_base} + {2'b00, brightness};

    // CLAMPING: Nếu > 255 thì giữ ở 255
    wire [7:0] gray_final = (gray_bright > 10'd255) ? 8'd255 : gray_bright[7:0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_out  <= 8'd0;
            out_valid <= 1'b0;
        end else begin
            gray_out  <= gray_final;
            out_valid <= in_valid;
        end
    end

endmodule 