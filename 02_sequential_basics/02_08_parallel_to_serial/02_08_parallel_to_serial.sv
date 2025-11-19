//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module parallel_to_serial
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      parallel_valid,
    input        [width - 1:0] parallel_data,

    output                     busy,
    output logic               serial_valid,
    output logic               serial_data
);
    // Task:
    // Implement a module that converts multi-bit parallel value to the single-bit serial data.
    //
    // The module should accept 'width' bit input parallel data when 'parallel_valid' input is asserted.
    // At the same clock cycle as 'parallel_valid' is asserted, the module should output
    // the least significant bit of the input data. In the following clock cycles the module
    // should output all the remaining bits of the parallel_data.
    // Together with providing correct 'serial_data' value, module should also assert the 'serial_valid' output.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.


    logic [width - 1:0] par_data;
    logic taken;
    logic [2:0] cur_numb;
    
    assign busy = taken;
    assign serial_data = par_data[0];
    assign serial_valid = taken;
    always_ff @ (posedge clk) begin
	    if (rst) begin
		    par_data <= '0;
		    taken <= 1'b0;
		    cur_numb <= '0;
	    end
	    if (parallel_valid && !taken) begin
		    par_data <= parallel_data;
		    cur_numb <= '0;
		    taken <= 1'b1;
	    end
	    else if (taken) begin
		    par_data <= {1'b0, par_data[width-1:1]};
		    cur_numb <= cur_numb + 1;
		    
		    if (cur_numb == width - 1) begin
			    taken <= 1'b0;
		    end 
	    end
    end
endmodule
