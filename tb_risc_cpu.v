`timescale 1ns/1ps

module tb_risc_cpu;

    reg clk;
    reg rst;
    wire halt;
    integer cycles;
    integer i;
    integer done;
    integer total_fail;
    integer test_fail;

    // opcode_seen[opcode] = 1 when that opcode executed at least once
    reg [7:0] opcode_seen;

    // Opcode map (same as controller/alu)
    localparam HLT = 3'b000;
    localparam SKZ = 3'b001;
    localparam ADD = 3'b010;
    localparam AND = 3'b011;
    localparam XOR = 3'b100;
    localparam LDA = 3'b101;
    localparam STO = 3'b110;
    localparam JMP = 3'b111;

    // Limit each run so bad programs do not hang forever
    localparam MAX_CYCLES = 2000;

    risc_cpu dut (
        .clk(clk),
        .rst(rst),
        .halt(halt)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task expect_mem;
        input [4:0] addr;
        input [7:0] expected;
        input [8*32-1:0] tag;
        begin
            if (dut.mem_inst.ram[addr] !== expected) begin
                $display("[FAIL] %0s M[%0d]=0x%02x expected=0x%02x",
                         tag, addr, dut.mem_inst.ram[addr], expected);
                total_fail = total_fail + 1;
                test_fail = test_fail + 1;
            end else begin
                $display("[PASS] %0s M[%0d]=0x%02x", tag, addr, dut.mem_inst.ram[addr]);
            end
        end
    endtask

    task run_one_program;
        input [8*64-1:0] prog_file;
        input [4:0] expected_halt_pc;
        input [7:0] required_ops_mask;
        input [7:0] exact_ops_mask;
        begin
            test_fail = 0;
            $display("");
            $display("========== Running %0s ==========", prog_file);

            // Clear RAM so each test starts clean
            for (i = 0; i < 32; i = i + 1) begin
                dut.mem_inst.ram[i] = 8'h00;
            end

            // Load this program image
            $readmemb(prog_file, dut.mem_inst.ram);

            // Reset coverage and CPU
            opcode_seen = 8'h00;
            rst = 1'b1;
            repeat (2) @(posedge clk);
            rst = 1'b0;

            // Run until HLT decode at OP_ADDR or timeout
            cycles = 0;
            done = 0;
            while (!done && (cycles < MAX_CYCLES)) begin
                @(posedge clk);
                #1;
                cycles = cycles + 1;

                if (!rst && (dut.ctrl_inst.state == dut.ctrl_inst.OP_ADDR)) begin
                    opcode_seen[dut.ir_out[7:5]] = 1'b1;
                    if (dut.ir_out[7:5] == HLT) begin
                        done = 1;
                    end
                end
            end

            if (!done) begin
                $display("[FAIL] %0s timed out after %0d cycles", prog_file, MAX_CYCLES);
                total_fail = total_fail + 1;
                test_fail = test_fail + 1;
            end else begin
                $display("[PASS] %0s reached HLT in %0d cycles", prog_file, cycles);
            end

            if (dut.pc_out !== expected_halt_pc) begin
                $display("[FAIL] %0s halt PC=%0d expected=%0d", prog_file, dut.pc_out, expected_halt_pc);
                total_fail = total_fail + 1;
                test_fail = test_fail + 1;
            end else begin
                $display("[PASS] %0s halt PC=%0d", prog_file, dut.pc_out);
            end

            // Operation coverage checks for this program
            if ((opcode_seen & required_ops_mask) != required_ops_mask) begin
                $display("[FAIL] %0s missing required operations. seen=%b required=%b",
                         prog_file, opcode_seen, required_ops_mask);
                total_fail = total_fail + 1;
                test_fail = test_fail + 1;
            end else begin
                $display("[PASS] %0s required operation coverage ok. seen=%b", prog_file, opcode_seen);
            end

            if (opcode_seen !== exact_ops_mask) begin
                $display("[FAIL] %0s exact operation mask mismatch. seen=%b expected=%b",
                         prog_file, opcode_seen, exact_ops_mask);
                total_fail = total_fail + 1;
                test_fail = test_fail + 1;
            end else begin
                $display("[PASS] %0s exact operation mask ok. seen=%b", prog_file, opcode_seen);
            end

            if (test_fail == 0) begin
                $display("[PASS] %0s summary: all checks passed", prog_file);
            end else begin
                $display("[FAIL] %0s summary: %0d check(s) failed", prog_file, test_fail);
            end
        end
    endtask

    initial begin
        total_fail = 0;
        rst = 1'b0;

        // Bit index = opcode number:
        // bit0 HLT, bit1 SKZ, bit2 ADD, bit3 AND, bit4 XOR, bit5 LDA, bit6 STO, bit7 JMP

        // PROG1 expected pass point: HLT at address 0x17
        run_one_program("PROG1.txt", 5'h17, 8'b11110011, 8'b11110011);
        expect_mem(5'h1A, 8'h00, "PROG1 DATA_1");
        expect_mem(5'h1B, 8'hFF, "PROG1 DATA_2");
        expect_mem(5'h1C, 8'h00, "PROG1 TEMP");

        // PROG2 expected pass point: HLT at address 0x10
        run_one_program("PROG2.txt", 5'h10, 8'b11111111, 8'b11111111);
        expect_mem(5'h1A, 8'h01, "PROG2 DATA_1");
        expect_mem(5'h1B, 8'hAA, "PROG2 DATA_2");
        expect_mem(5'h1C, 8'hFF, "PROG2 DATA_3");
        expect_mem(5'h1D, 8'hFF, "PROG2 TEMP");

        // PROG3 expected pass point: HLT at address 0x0C
        run_one_program("PROG3.txt", 5'h0C, 8'b11110111, 8'b11110111);
        expect_mem(5'h1A, 8'h90, "PROG3 FN1");
        expect_mem(5'h1B, 8'hE9, "PROG3 FN2");
        expect_mem(5'h1C, 8'h90, "PROG3 TEMP");
        expect_mem(5'h1D, 8'h90, "PROG3 LIMIT");
        expect_mem(5'h1E, 8'h00, "PROG3 ZERO");
        expect_mem(5'h1F, 8'h01, "PROG3 ONE");

        if (total_fail == 0) begin
            $display("ALL PROGRAMS PASSED");
        end else begin
            $display("REGRESSION FAILED: %0d issue(s)", total_fail);
        end

        #20;
        $finish;
    end

    initial begin
        $dumpfile("risc_cpu.vcd");
        $dumpvars(0, tb_risc_cpu);
    end

endmodule
