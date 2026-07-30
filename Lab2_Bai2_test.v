// ============================================================
//  Module  : image_to_grayscale
//  Desc    : Convert 8-bit RGB pixel to grayscale using
//            standard formula Y = 0.299R + 0.587G + 0.114B
//            Approximated with integer coefficients (* 256):
//              R * 77 + G * 150 + B * 29  (sum / 256)
//            Brightness is an OFFSET added after conversion:
//              gray_final = clamp(gray_base + brightness_offset, 0, 255)
//            where brightness_offset is signed (-128 to +127)
//            encoded as unsigned 8-bit (128 = no change).
//  Latency : 1 clock cycle (registered output)
// ============================================================

module image_to_grayscale (
    input  wire        clk,
    input  wire        rst_n,

    // Pixel input
    input  wire [7:0]  r_in,
    input  wire [7:0]  g_in,
    input  wire [7:0]  b_in,
    input  wire        in_valid,

    // Brightness control:
    //   128 (0x80) = no change
    //   > 128      = brighter  (max +127)
    //   < 128      = darker    (max -128)
    input  wire [7:0]  brightness,

    // Output
    output reg  [7:0]  gray_out,
    output reg         out_valid
);

    // ----------------------------------------------------------
    // Stage 1 (combinational): multiply-accumulate
    // Coefficients: 77, 150, 29  (sum = 256, scaled by 1/256)
    // Each product is 8*8 = 16 bits; accumulator needs 18 bits.
    // ----------------------------------------------------------
    wire [15:0] r_mul = r_in * 8'd77;    // 0.299 * 256 = 76.544 ≈ 77
    wire [15:0] g_mul = g_in * 8'd150;   // 0.587 * 256 = 150.27 ≈ 150
    wire [15:0] b_mul = b_in * 8'd29;    // 0.114 * 256 = 29.18  ≈ 29

    wire [17:0] acc         = {2'b00, r_mul} + {2'b00, g_mul} + {2'b00, b_mul};
    wire [17:0] acc_rounded = acc + 18'd128;   // round instead of truncate
    wire [7:0]  gray_base   = acc_rounded[15:8]; // divide by 256 (drop lower 8 bits)

    // ----------------------------------------------------------
    // Stage 2 (combinational): apply brightness offset
    // brightness is unsigned 8-bit with bias 128.
    // signed_offset = brightness - 128  →  range [-128, +127]
    // Use 10-bit signed arithmetic to detect over/underflow.
    // ----------------------------------------------------------
    wire signed [9:0]  signed_offset = $signed({1'b0, brightness}) - 10'sd128;
    wire signed [9:0]  gray_bright   = $signed({2'b00, gray_base}) + signed_offset;

    // Clamp to [0, 255]
    wire [7:0] gray_final = (gray_bright > 10'sd255) ? 8'd255 :
                            (gray_bright < 10'sd0  ) ? 8'd0   :
                             gray_bright[7:0];

    // ----------------------------------------------------------
    // Stage 3 (registered): latch output
    // ----------------------------------------------------------
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