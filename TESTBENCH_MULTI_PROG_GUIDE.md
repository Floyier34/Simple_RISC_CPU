# Testbench regression for all `PROG*.txt` programs

This guide shows how to run the same CPU testbench against multiple program files and verify instruction coverage (operations executed).

## 0) Prepare program files

Right now the repo has `PROG1.txt`, while `PROG2`/`PROG3` are `.docx`.

Create text versions first:

- `PROG2.txt`
- `PROG3.txt`

Use the same format as `PROG1.txt` (`@addr`, binary words, optional `//` comments).

## 1) Replace `tb_risc_cpu.v` with a regression-style testbench

Use this testbench template:

```verilog
`timescale 1ns/1ps

module tb_risc_cpu;

    reg clk;
    reg rst;
    wire halt;
    integer cycles;
    integer i;
    integer total_fail;

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

    // Count executed opcodes at end of instruction cycle
    always @(posedge clk) begin
        if (!rst && (dut.ctrl_inst.state == dut.ctrl_inst.STORE)) begin
            opcode_seen[dut.ir_out[7:5]] <= 1'b1;
        end
    end

    task run_one_program;
        input [8*64-1:0] prog_file;
        input [7:0] required_ops_mask;
        begin
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

            // Run until HALT or timeout
            cycles = 0;
            while (!halt && (cycles < MAX_CYCLES)) begin
                @(posedge clk);
                cycles = cycles + 1;
            end

            if (cycles >= MAX_CYCLES) begin
                $display("[FAIL] %0s timed out after %0d cycles", prog_file, MAX_CYCLES);
                total_fail = total_fail + 1;
            end else begin
                $display("[PASS] %0s halted in %0d cycles", prog_file, cycles);
            end

            // Operation coverage check for this program
            if ((opcode_seen & required_ops_mask) != required_ops_mask) begin
                $display("[FAIL] %0s missing required operations. seen=%b required=%b",
                         prog_file, opcode_seen, required_ops_mask);
                total_fail = total_fail + 1;
            end else begin
                $display("[PASS] %0s operation coverage ok. seen=%b", prog_file, opcode_seen);
            end
        end
    endtask

    initial begin
        total_fail = 0;
        rst = 1'b0;

        // Bit index = opcode number:
        // bit0 HLT, bit1 SKZ, bit2 ADD, bit3 AND, bit4 XOR, bit5 LDA, bit6 STO, bit7 JMP

        // PROG1 uses HLT, SKZ, XOR, LDA, STO, JMP
        run_one_program("PROG1.txt", 8'b11110011);

        // Enable these after creating text files:
        // run_one_program("PROG2.txt", 8'b11111111); // if it should touch all ops
        // run_one_program("PROG3.txt", 8'b11111111); // adjust mask to your spec

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
```

## 2) How to set `required_ops_mask`

`required_ops_mask` is an 8-bit bitmap where bit index = opcode:

- bit0=`HLT`
- bit1=`SKZ`
- bit2=`ADD`
- bit3=`AND`
- bit4=`XOR`
- bit5=`LDA`
- bit6=`STO`
- bit7=`JMP`

Examples:

- all ops required: `8'b11111111`
- only `HLT, SKZ, LDA, STO, JMP`: `8'b11100011`
- `PROG1` from your current file: `8'b11110011` (`HLT, SKZ, XOR, LDA, STO, JMP`)

## 3) Run regression

Example with Icarus:

```powershell
iverilog -o a.out tb_risc_cpu.v risc_cpu.v controller.v memory.v alu.v address_mux.v register.v program_counter.v
vvp a.out
```

If you later split into separate testbenches, keep one run command per file and aggregate in a batch script.

## 4) Notes

- This approach uses hierarchical access (`dut.mem_inst.ram`, `dut.ctrl_inst.state`) for verification only.
- If your simulator dislikes underscore separators in `PROG*.txt` data words (for example `111_11110`), remove underscores in the data tokens.

