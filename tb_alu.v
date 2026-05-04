`timescale 1ns/1ps

module tb_alu;

    reg [2:0] opcode;
    reg [7:0] inA;
    reg [7:0] inB;
    wire [7:0] out;
    wire is_zero;

    integer fail_count;

    localparam HLT = 3'b000;
    localparam SKZ = 3'b001;
    localparam ADD = 3'b010;
    localparam AND = 3'b011;
    localparam XOR = 3'b100;
    localparam LDA = 3'b101;
    localparam STO = 3'b110;
    localparam JMP = 3'b111;

    alu dut (
        .opcode(opcode),
        .inA(inA),
        .inB(inB),
        .out(out),
        .is_zero(is_zero)
    );

    task expect_out;
        input [7:0] expected;
        input [8*40-1:0] tag;
        begin
            #1;
            if (out !== expected) begin
                $display("[FAIL] %0s out=0x%02x expected=0x%02x", tag, out, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s out=0x%02x", tag, out);
            end
        end
    endtask

    task expect_zero;
        input expected;
        input [8*40-1:0] tag;
        begin
            #1;
            if (is_zero !== expected) begin
                $display("[FAIL] %0s is_zero=%0b expected=%0b", tag, is_zero, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s is_zero=%0b", tag, is_zero);
            end
        end
    endtask

    initial begin
        fail_count = 0;

        inA = 8'h3C;
        inB = 8'h0F;

        opcode = HLT;
        expect_out(8'h3C, "HLT returns inA");

        opcode = SKZ;
        expect_out(8'h3C, "SKZ returns inA");

        opcode = ADD;
        expect_out(8'h4B, "ADD inA + inB");

        opcode = AND;
        expect_out(8'h0C, "AND inA & inB");

        opcode = XOR;
        expect_out(8'h33, "XOR inA ^ inB");

        opcode = LDA;
        expect_out(8'h0F, "LDA returns inB");

        opcode = STO;
        expect_out(8'h3C, "STO returns inA");

        opcode = JMP;
        expect_out(8'h3C, "JMP returns inA");

        // is_zero checks are asynchronous to opcode
        inA = 8'h00;
        expect_zero(1'b1, "is_zero asserted when inA=0");

        inA = 8'h01;
        expect_zero(1'b0, "is_zero deasserted when inA!=0");

        if (fail_count == 0) begin
            $display("tb_alu: ALL TESTS PASSED");
        end else begin
            $display("tb_alu: %0d TEST(S) FAILED", fail_count);
        end

        #5;
        $finish;
    end

endmodule
