//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module conv_last_to_first
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    input                up_last,
    input  [width - 1:0] up_data,

    output               down_valid,
    output               down_first,
    output [width - 1:0] down_data
);
    // Task:
    // Implement a module that converts 'last' input status signal
    // to the 'first' output status signal.
    //
    // See README for full description of the task with timing diagram.

    reg next_is_first;
    reg [width - 1:0] data_to_return;
    reg down_first_reg;
    reg validation;

    assign down_first = down_first_reg;
    assign down_data = data_to_return;
    assign down_valid = validation;

    always_ff @ (posedge clock)
	    if (reset) begin
		    down_first_reg <= 1'b0;
		    data_to_return <= '0;
		    next_is_first <= 1'b1;
		    validation <= 1'b0;
	    end else begin
		    validation <= 1'b0;
		    down_first_reg <= 1'b0;
		    if (up_valid) begin
			    data_to_return <= up_data;
			    validation <= 1'b1;
			    down_first_reg <= next_is_first;
			    if (up_last) begin
				    next_is_first <= 1'b1;
			    end else begin
				    next_is_first <= 1'b0;
			    end
		    end
	    end

endmodule
