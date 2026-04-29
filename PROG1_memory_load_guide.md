# Load `PROG1.txt` directly in `memory.v`

Use this approach so memory initializes itself from file, instead of assigning `dut.mem_inst.ram[...]` in the testbench.

## 1) Update `memory.v`

Replace your module header and add an `initial` block:

```verilog
module memory #(
    parameter INIT_FILE = "PROG1.txt"
) (
    input clk,
    input rd,
    input wr,
    input [4:0] addr,
    inout [7:0] data
);

    reg [7:0] ram [0:31];
    reg [7:0] data_out;
    integer index;

    assign data = (rd && !wr) ? data_out : 8'bzzzzzzzz;

    initial begin
        for (index = 0; index < 32; index = index + 1) begin
            ram[index] = 8'h00;
        end
        $readmemb(INIT_FILE, ram);
    end
```

Keep the rest of your read/write logic as-is.

## 2) Remove DUT memory pokes in `tb_risc_cpu.v`

Delete lines like:

```verilog
dut.mem_inst.ram[0] = 8'b10101010;
...
dut.mem_inst.ram[12] = 8'd0;
```

After this, reset/start simulation normally; memory content comes from `PROG1.txt`.

## 3) Keep `PROG1.txt` simulator-friendly

Your current file is already close to valid for `$readmemb`:

- `@00`, `@1A`, `@1E` are valid address jumps.
- `0/1` binary tokens are valid.
- `//` comments are allowed by most simulators.

If your simulator rejects underscores (for example `111_11110`), remove underscores in data fields only.

## 4) Optional: choose program per test

In testbench, you can override the file without editing `memory.v`:

```verilog
defparam dut.mem_inst.INIT_FILE = "PROG1.txt";
```

Or instantiate with parameter override if your hierarchy allows it.

