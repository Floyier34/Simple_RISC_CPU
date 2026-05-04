`timescale 1ns/1ps

module tb_address_mux;

    reg [4:0] inst_addr5;
    reg [4:0] op_addr5;
    reg sel5;
    wire [4:0] addr5;

    reg [7:0] inst_addr8;
    reg [7:0] op_addr8;
    reg sel8;
    wire [7:0] addr8;

    integer fail_count;

    address_mux dut_default (
        .inst_addr(inst_addr5),
        .op_addr(op_addr5),
        .sel(sel5),
        .addr(addr5)
    );

    address_mux #(.WIDTH(8)) dut_width8 (
        .inst_addr(inst_addr8),
        .op_addr(op_addr8),
        .sel(sel8),
        .addr(addr8)
    );

    task expect_addr5;
        input [4:0] expected;
        input [8*40-1:0] tag;
        begin
            if (addr5 !== expected) begin
                $display("[FAIL] %0s addr5=%0d expected=%0d", tag, addr5, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s addr5=%0d", tag, addr5);
            end
        end
    endtask

    task expect_addr8;
        input [7:0] expected;
        input [8*40-1:0] tag;
        begin
            if (addr8 !== expected) begin
                $display("[FAIL] %0s addr8=0x%02x expected=0x%02x", tag, addr8, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s addr8=0x%02x", tag, addr8);
            end
        end
    endtask

    initial begin
        fail_count = 0;

        inst_addr5 = 5'd3;
        op_addr5 = 5'd21;
        sel5 = 1'b1;
        #1;
        expect_addr5(5'd3, "sel=1 uses inst_addr (WIDTH=5)");

        sel5 = 1'b0;
        #1;
        expect_addr5(5'd21, "sel=0 uses op_addr (WIDTH=5)");

        inst_addr5 = 5'd31;
        op_addr5 = 5'd0;
        sel5 = 1'b1;
        #1;
        expect_addr5(5'd31, "boundary value check (WIDTH=5)");

        inst_addr8 = 8'hA5;
        op_addr8 = 8'h3C;
        sel8 = 1'b1;
        #1;
        expect_addr8(8'hA5, "sel=1 uses inst_addr (WIDTH=8)");

        sel8 = 1'b0;
        #1;
        expect_addr8(8'h3C, "sel=0 uses op_addr (WIDTH=8)");

        if (fail_count == 0) begin
            $display("tb_address_mux: ALL TESTS PASSED");
        end else begin
            $display("tb_address_mux: %0d TEST(S) FAILED", fail_count);
        end

        #5;
        $finish;
    end

endmodule
