`timescale 1ns/1ps

module tb_instruction_register;

    reg clk;
    reg rst;
    reg ld;
    reg [7:0] data_in;
    wire [7:0] data_out;

    integer fail_count;

    // IR uses the generic register module, WIDTH=8
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

    task expect_ir;
        input [7:0] expected;
        input [8*48-1:0] tag;
        begin
            if (data_out !== expected) begin
                $display("[FAIL] %0s ir=0x%02x expected=0x%02x", tag, data_out, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s ir=0x%02x", tag, data_out);
            end
        end
    endtask

    initial begin
        fail_count = 0;
        rst = 1'b0;
        ld = 1'b0;
        data_in = 8'h00;

        // Reset on clock edge
        rst = 1'b1;
        @(posedge clk);
        #1;
        expect_ir(8'h00, "reset clears IR");

        // Load instruction
        rst = 1'b0;
        ld = 1'b1;
        data_in = 8'hA7;
        @(posedge clk);
        #1;
        expect_ir(8'hA7, "ld=1 loads instruction");

        // Hold when ld=0
        ld = 1'b0;
        data_in = 8'h3C;
        @(posedge clk);
        #1;
        expect_ir(8'hA7, "ld=0 holds previous instruction");

        // Load new instruction
        ld = 1'b1;
        data_in = 8'h1F;
        @(posedge clk);
        #1;
        expect_ir(8'h1F, "load next instruction");

        if (fail_count == 0) begin
            $display("tb_instruction_register: ALL TESTS PASSED");
        end else begin
            $display("tb_instruction_register: %0d TEST(S) FAILED", fail_count);
        end

        #10;
        $finish;
    end

endmodule
