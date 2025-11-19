//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module double_tokens
(
    input        clk,
    input        rst,
    input        a,
    output       b,
    output logic overflow
);
    // Task:
    // Implement a serial module that doubles each incoming token '1' two times.
    // The module should handle doubling for at least 200 tokens '1' arriving in a row.
    //
    // In case module detects more than 200 sequential tokens '1', it should assert
    // an overflow error. The overflow error should be sticky. Once the error is on,
    // the only way to clear it is by using the "rst" reset signal.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // a -> 10010011000110100001100100
    // b -> 11011011110111111001111110

    logic [7:0] cntr = 0;
    logic overflow_clear;
    logic ron;

    always_ff @ (posedge clk) begin
	    if (rst) begin
		    overflow_clear <= 1'b0;
	    end
	    if (~overflow) begin
		    if (cntr > 200) begin
			    overflow_clear <= 1'b1;
		    end
		    else begin
			    if (a) begin
				    cntr += 2;
			    end
			    if (cntr) begin
				    ron <= 1'b1;
				    cntr -= 1;
			    end
			    else begin
				    ron <= 1'b0;
			    end
		    end
	    end
    end
    assign b = ron;
    assign overflow = overflow_clear;
endmodule
