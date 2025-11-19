//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module serial_to_parallel
# (
    parameter width = 8
)
(
    input                      clk,
    input                      rst,

    input                      serial_valid,
    input                      serial_data,

    output logic               parallel_valid,
    output logic [width - 1:0] parallel_data
);
    // Task:
    // Implement a module that converts serial data to the parallel multibit value.
    //
    // The module should accept one-bit values with valid interface in a serial manner.
    // After accumulating 'width' bits, the module should assert the parallel_valid
    // output and set the data.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.


    logic [width - 1:0] par_data;
    logic [2:0] number_in_check;

    assign parallel_valid = serial_valid && (number_in_check == width - 1);
    assign parallel_data = parallel_valid ? {serial_data, par_data[width-1:1]} : par_data;
    always_ff @ (posedge clk) begin
	    if (rst) begin
		    par_data <= '0;
		    number_in_check <= '0;
	    end
	    else begin
		    if (serial_valid) begin
			    par_data <= {serial_data, par_data[width-1:1]};
			    if (number_in_check == width - 1)
				    number_in_check <= '0;
			    else
				    number_in_check <= number_in_check + 1;
		    end
	    end
    end

endmodule
