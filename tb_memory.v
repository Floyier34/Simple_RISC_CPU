`timescale 1ns/1ps

module tb_memory;

    reg clk;
    reg rd;
    reg wr;
    reg [4:0] addr;
    wire [7:0] data;

    reg [7:0] data_drv;
    reg data_drv_en;
    integer fail_count;

    assign data = data_drv_en ? data_drv : 8'bzzzzzzzz;

    memory #(
        .INIT_FILE("tb_memory_init.txt")
    ) dut (
        .clk(clk),
        .rd(rd),
        .wr(wr),
        .addr(addr),
        .data(data)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task expect_data;
        input [7:0] expected;
        input [8*48-1:0] tag;
        begin
            if (data !== expected) begin
                $display("[FAIL] %0s data=0x%02x expected=0x%02x", tag, data, expected);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s data=0x%02x", tag, data);
            end
        end
    endtask

    task expect_hiz;
        input [8*48-1:0] tag;
        begin
            if (data !== 8'bzzzzzzzz) begin
                $display("[FAIL] %0s data is not Z (data=0x%02x)", tag, data);
                fail_count = fail_count + 1;
            end else begin
                $display("[PASS] %0s data bus is Z", tag);
            end
        end
    endtask

    initial begin
        fail_count = 0;
        rd = 1'b0;
        wr = 1'b0;
        addr = 5'd0;
        data_drv = 8'h00;
        data_drv_en = 1'b0;

        // Allow init phase to settle
        @(posedge clk);
        #1;

        // Read from initialized memory
        addr = 5'd5;
        rd = 1'b1;
        wr = 1'b0;
        data_drv_en = 1'b0;
        @(posedge clk);
        #1;
        expect_data(8'h05, "read initialized location M[5]");

        addr = 5'd31;
        @(posedge clk);
        #1;
        expect_data(8'h1F, "read initialized location M[31]");

        // No read/write: data bus must be Z
        rd = 1'b0;
        wr = 1'b0;
        #1;
        expect_hiz("idle mode drives no data");

        // Write memory location
        addr = 5'd10;
        data_drv = 8'hA5;
        data_drv_en = 1'b1;
        rd = 1'b0;
        wr = 1'b1;
        @(posedge clk);
        #1;
        if (data !== 8'hA5) begin
            $display("[FAIL] write mode should leave external driver visible");
            fail_count = fail_count + 1;
        end else begin
            $display("[PASS] write mode: external driver controls bus");
        end

        // In write mode, if external side releases bus, it should be Z
        data_drv_en = 1'b0;
        #1;
        expect_hiz("write mode does not drive bus from memory");

        // Read back written value
        rd = 1'b1;
        wr = 1'b0;
        @(posedge clk);
        #1;
        expect_data(8'hA5, "read back written value M[10]");

        // Illegal simultaneous rd/wr: model should neither drive bus nor write
        addr = 5'd11;
        data_drv = 8'h5A;
        data_drv_en = 1'b1;
        rd = 1'b1;
        wr = 1'b1;
        @(posedge clk);
        #1;
        // While both active, memory should not drive
        if (data !== 8'h5A) begin
            $display("[FAIL] simultaneous rd/wr should leave external driver visible");
            fail_count = fail_count + 1;
        end else begin
            $display("[PASS] simultaneous rd/wr: external driver controls bus");
        end

        // Verify M[11] unchanged from init value 0x0B
        data_drv_en = 1'b0;
        rd = 1'b1;
        wr = 1'b0;
        @(posedge clk);
        #1;
        expect_data(8'h0B, "M[11] unchanged after rd=wr=1");

        if (fail_count == 0) begin
            $display("tb_memory: ALL TESTS PASSED");
        end else begin
            $display("tb_memory: %0d TEST(S) FAILED", fail_count);
        end

        #10;
        $finish;
    end

endmodule
