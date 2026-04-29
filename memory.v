// module memory (
//     input clk,
//     input rd,
//     input wr,
//     input [4:0] addr,
//     inout [7:0] data
// );

//     reg [7:0] ram [0:31];
//     reg [7:0] data_out;

//     assign data = (rd && !wr) ? data_out : 8'bzzzzzzzz;

//     always @(posedge clk) begin
//         if (wr && !rd) begin
//             ram[addr] <= data;
//         end else begin
//             ram[addr] <= ram[addr];
//         end
//     end

//     always @(posedge clk) begin
//         if (rd && !wr) begin
//             data_out <= ram[addr];
//         end else begin
//             data_out <= data_out;
//         end
//     end

// endmodule

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
        // for (index = 0; index < 32; index = index + 1) begin
        //     ram[index] = 8'h00;
        // end
        $readmemb(INIT_FILE, ram);
    end

    always @(posedge clk) begin
        if (wr && !rd) begin
            ram[addr] <= data;
        end else begin
            ram[addr] <= ram[addr];
        end
    end

    always @(posedge clk) begin
        if (rd && !wr) begin
            data_out <= ram[addr];
        end else begin
            data_out <= data_out;
        end
    end

endmodule


