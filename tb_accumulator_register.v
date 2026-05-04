`timescale 1ns/1ps

module tb_accumulator_register;

    reg clk;
    reg rst;
    reg ld;
    reg [7:0] data_in;
    wire [7:0] data_out;

    integer fail_count;

    // ACC also uses generic register module, WIDTH=8
    register #(.WIDTH(8)) dut (
        .clk(clk),
        .rst(rst),
        .ld(ld),
        .data_in(data_in),
        .data_out(data_out)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task expect_ac;
        input [7:0] expected;
        input [8*48-1:0] tag;
        begin
            if (data_out !== expected) begin
                $display("[FAIL] %0s ac=0x%02x expected=0x%02x", tag, data_out, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s ac=0x%02x", tag, data_out);
            end
        end
    endtask

    initial begin
        fail_count = 0;
        rst = 1'b0;
        ld = 1'b0;
        data_in = 8'h00;

        // Reset behavior
        rst = 1'b1;
        @(posedge clk);
        #1;
        expect_ac(8'h00, "reset clears accumulator");

        // First ALU result load
        rst = 1'b0;
        ld = 1'b1;
        data_in = 8'h55;
        @(posedge clk);
        #1;
        expect_ac(8'h55, "load ALU result #1");

        // Hold old result
        ld = 1'b0;
        data_in = 8'hAA;
        @(posedge clk);
        #1;
        expect_ac(8'h55, "hold when ld=0");

        // Load second ALU result
        ld = 1'b1;
        data_in = 8'hAA;
        @(posedge clk);
        #1;
        expect_ac(8'hAA, "load ALU result #2");

        if (fail_count == 0) begin
            $display("tb_accumulator_register: ALL TESTS PASSED");
        end else begin
            $display("tb_accumulator_register: %0d TEST(S) FAILED", fail_count);
        end

        #10;
        $finish;
    end

endmodule
