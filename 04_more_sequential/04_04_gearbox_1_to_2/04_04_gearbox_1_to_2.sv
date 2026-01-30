//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2
# (
    parameter width = 0
)
(
    input                    clk,
    input                    rst,

    input                    up_vld,    // upstream
    input  [    width - 1:0] up_data,

    output                   down_vld,  // downstream
    output [2 * width - 1:0] down_data
);
    // Task:
    // Implement a module that transforms a stream of data
    // from 'width' to the 2*'width' data width.
    //
    // The module should be capable to accept new data at each
    // clock cycle and produce concatenated 'down_data'
    // at each second clock cycle.
    //
    // The module should work properly with reset 'rst'
    // and valid 'vld' signals

    reg down_vld_reg;
    reg [2*width - 1:0] down_data_reg;
    reg has_first_part;
    reg [width - 1:0] first_part_word;


    assign down_vld = down_vld_reg;
    assign down_data = down_data_reg;

    always_ff @ (posedge clk)
	    if (rst) begin
		    down_vld_reg <= 1'b0;
		    down_data_reg <= '0;
		    has_first_part <= 1'b0;
		    first_part_word <= '0;
	    end
	    else begin
		    down_vld_reg <= 1'b0;
		    if (up_vld) begin
			    if (!has_first_part) begin 
				    has_first_part <= up_vld;
				    first_part_word <= up_data;
			    end else begin
				    down_data_reg <= {first_part_word, up_data};
				    down_vld_reg <= 1'b1;
				    has_first_part <= 1'b0;
			    end
		    end

		    
	    end
endmodule
