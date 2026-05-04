`timescale 1ns/1ps

module tb_program_counter;

    reg clk;
    reg rst;
    reg ld_pc;
    reg inc_pc;
    reg [4:0] in_pc;
    wire [4:0] pc;

    integer fail_count;

    program_counter dut (
        .clk(clk),
        .rst(rst),
        .ld_pc(ld_pc),
        .inc_pc(inc_pc),
        .in_pc(in_pc),
        .pc(pc)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task expect_pc;
        input [4:0] expected;
        input [8*40-1:0] tag;
        begin
            if (pc !== expected) begin
                $display("[FAIL] %0s pc=%0d expected=%0d", tag, pc, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s pc=%0d", tag, pc);
            end
        end
    endtask

    initial begin
        fail_count = 0;
        rst = 1'b0;
        ld_pc = 1'b0;
        inc_pc = 1'b0;
        in_pc = 5'd0;

        // Reset active on clock edge
        rst = 1'b1;
        @(posedge clk);
        #1;
        expect_pc(5'd0, "reset clears pc");

        // Load a custom value
        rst = 1'b0;
        ld_pc = 1'b1;
        in_pc = 5'd13;
        @(posedge clk);
        #1;
        expect_pc(5'd13, "ld_pc loads in_pc");

        // Hold value when no control signal
        ld_pc = 1'b0;
        inc_pc = 1'b0;
        in_pc = 5'd31;
        @(posedge clk);
        #1;
        expect_pc(5'd13, "hold when ld_pc=0 and inc_pc=0");

        // Increment
        inc_pc = 1'b1;
        @(posedge clk);
        #1;
        expect_pc(5'd14, "inc_pc increments");

        // Priority: ld_pc over inc_pc
        ld_pc = 1'b1;
        in_pc = 5'd7;
        inc_pc = 1'b1;
        @(posedge clk);
        #1;
        expect_pc(5'd7, "ld_pc has higher priority than inc_pc");

        // Wrap-around check (5-bit)
        ld_pc = 1'b1;
        inc_pc = 1'b0;
        in_pc = 5'd31;
        @(posedge clk);
        #1;
        expect_pc(5'd31, "load max value");

        ld_pc = 1'b0;
        inc_pc = 1'b1;
        @(posedge clk);
        #1;
        expect_pc(5'd0, "increment wraps around");

        if (fail_count == 0) begin
            $display("tb_program_counter: ALL TESTS PASSED");
        end else begin
            $display("tb_program_counter: %0d TEST(S) FAILED", fail_count);
        end

        #10;
        $finish;
    end

endmodule
