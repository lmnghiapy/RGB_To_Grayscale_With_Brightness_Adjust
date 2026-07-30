// ============================================================
//  Testbench : tb_image_to_grayscale
//  Tests     :
//    1. Reset check
//    2. Pure Red / Green / Blue pixels
//    3. White and Black pixels
//    4. Brightness = 128 (no change)
//    5. Brightness > 128 (brighten) with clamping at 255
//    6. Brightness < 128 (darken)  with clamping at 0
//    7. Random pixel stream with in_valid toggling
// ============================================================

`timescale 1ns/1ps

module tb_image_to_grayscale;

    // ---- DUT ports ----
    reg        clk;
    reg        rst_n;
    reg  [7:0] r_in, g_in, b_in;
    reg        in_valid;
    reg  [7:0] brightness;
    wire [7:0] gray_out;
    wire       out_valid;

    // ---- Instantiate DUT ----
    image_to_grayscale dut (
        .clk        (clk),
        .rst_n      (rst_n),
        .r_in       (r_in),
        .g_in       (g_in),
        .b_in       (b_in),
        .in_valid   (in_valid),
        .brightness (brightness),
        .gray_out   (gray_out),
        .out_valid  (out_valid)
    );

    // ---- Clock: 10 ns period (100 MHz) ----
    initial clk = 0;
    always #5 clk = ~clk;

    // ---- Helper task ----
    integer pass_count = 0;
    integer fail_count = 0;

    task apply_pixel;
        input [7:0] r, g, b, bright;
        input [7:0] expected;
        input [63:0] test_id;   // for display (use 8 chars max)
        begin
            @(negedge clk);
            r_in       = r;
            g_in       = g;
            b_in       = b;
            brightness = bright;
            in_valid   = 1'b1;
            @(posedge clk); #1;  // wait 1 cycle for registered output
            if (!out_valid) begin
                $display("FAIL [%s] out_valid=0", test_id);
                fail_count = fail_count + 1;
            end else if (gray_out !== expected) begin
                $display("FAIL [%s] R=%0d G=%0d B=%0d bright=%0d | got=%0d exp=%0d",
                          test_id, r, g, b, bright, gray_out, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("PASS [%s] R=%0d G=%0d B=%0d bright=%0d | gray=%0d",
                          test_id, r, g, b, bright, gray_out);
                pass_count = pass_count + 1;
            end
        end
    endtask

    // ---- Function: software reference ----
    function [7:0] sw_gray;
        input [7:0] r, g, b, bright;
        integer raw, offset, result;
        begin
            raw    = (r * 77 + g * 150 + b * 29 + 128) >> 8;
            offset = $signed({1'b0, bright}) - 128;
            result = raw + offset;
            if (result > 255) result = 255;
            if (result < 0)   result = 0;
            sw_gray = result[7:0];
        end
    endfunction

    integer i;
    reg [7:0] rr, gg, bb, br, exp;

    initial begin
        $dumpfile("tb_image_to_grayscale.vcd");
        $dumpvars(0, tb_image_to_grayscale);

        // ---- Init ----
        rst_n    = 0;
        in_valid = 0;
        r_in = 0; g_in = 0; b_in = 0;
        brightness = 8'd128;

        repeat(3) @(posedge clk);
        rst_n = 1;
        @(posedge clk);

        $display("\n=== TEST 1: Reset check ===");
        @(negedge clk);
        in_valid = 1'b0;
        @(posedge clk); #1;
        if (gray_out === 8'd0 && out_valid === 1'b0)
            $display("PASS Reset: gray_out=0, out_valid=0");
        else
            $display("FAIL Reset: gray_out=%0d, out_valid=%0b", gray_out, out_valid);

        $display("\n=== TEST 2: Pure color pixels (brightness=128, no change) ===");
        // Pure Red: Y = 77/256 * 255 ≈ 76
        apply_pixel(8'd255, 8'd0,   8'd0,   8'd128, sw_gray(255,0,0,128),   "PureRed");
        // Pure Green: Y = 150/256 * 255 ≈ 149
        apply_pixel(8'd0,   8'd255, 8'd0,   8'd128, sw_gray(0,255,0,128),   "PureGrn");
        // Pure Blue: Y = 29/256 * 255 ≈ 28
        apply_pixel(8'd0,   8'd0,   8'd255, 8'd128, sw_gray(0,0,255,128),   "PureBlu");

        $display("\n=== TEST 3: White and Black ===");
        apply_pixel(8'd255, 8'd255, 8'd255, 8'd128, sw_gray(255,255,255,128), "White  ");
        apply_pixel(8'd0,   8'd0,   8'd0,   8'd128, sw_gray(0,0,0,128),       "Black  ");

        $display("\n=== TEST 4: Brightness brighten (bright=200, +72 offset) ===");
        apply_pixel(8'd100, 8'd100, 8'd100, 8'd200, sw_gray(100,100,100,200), "Bright+");
        // Should clamp at 255
        apply_pixel(8'd200, 8'd200, 8'd200, 8'd255, sw_gray(200,200,200,255), "Clmp255");

        $display("\n=== TEST 5: Brightness darken (bright=50, -78 offset) ===");
        apply_pixel(8'd100, 8'd100, 8'd100, 8'd50,  sw_gray(100,100,100,50),  "Dark-  ");
        // Should clamp at 0
        apply_pixel(8'd10,  8'd10,  8'd10,  8'd0,   sw_gray(10,10,10,0),      "Clmp000");

        $display("\n=== TEST 6: in_valid = 0 (output should NOT update) ===");
        @(negedge clk);
        in_valid = 1'b0;
        r_in = 8'd255; g_in = 8'd0; b_in = 8'd0;
        brightness = 8'd128;
        @(posedge clk); #1;
        if (out_valid === 1'b0)
            $display("PASS in_valid=0: out_valid correctly 0");
        else
            $display("FAIL in_valid=0: out_valid=%0b (expected 0)", out_valid);

        $display("\n=== TEST 7: Random pixel stream ===");
        for (i = 0; i < 20; i = i + 1) begin
            rr = $random % 256;
            gg = $random % 256;
            bb = $random % 256;
            br = $random % 256;
            exp = sw_gray(rr, gg, bb, br);
            apply_pixel(rr, gg, bb, br, exp, "Random ");
        end

        @(negedge clk);
        in_valid = 1'b0;

        $display("\n=============================");
        $display("  TOTAL PASS: %0d", pass_count);
        $display("  TOTAL FAIL: %0d", fail_count);
        $display("=============================\n");

        #20;
        $finish;
    end

endmodule