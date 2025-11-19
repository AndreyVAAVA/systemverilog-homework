//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module round_robin_arbiter_with_2_requests
(
    input        clk,
    input        rst,
    input  [1:0] requests,
    output [1:0] grants
);
    // Task:
    // Implement a "arbiter" module that accepts up to two requests
    // and grants one of them to operate in a round-robin manner.
    //
    // The module should maintain an internal register
    // to keep track of which requester is next in line for a grant.
    //
    // Note:
    // Check the waveform diagram in the README for better understanding.
    //
    // Example:
    // requests -> 01 00 10 11 11 00 11 00 11 11
    // grants   -> 01 00 10 01 10 00 01 00 10 01

    logic priority_first;


    typedef enum logic [1:0] {
	    no_grant = 2'b00,
	    first_grant = 2'b01,
	    second_grant = 2'b10
    } grants_list;

    grants_list granted;

    always_comb begin
	    case(requests)
		   2'b00: granted = no_grant;
		   2'b01: granted = first_grant;
		   2'b10: granted = second_grant;
		   2'b11: begin
			   if (priority_first) begin
				   granted = second_grant;
			   end
			   else begin
				   granted = first_grant;
			   end
		   end
	   endcase
    end

    always_ff @ (posedge clk) begin
	    if (rst) begin
		    priority_first <= 1'b1;
	    end
	    else begin
		    if (granted == first_grant) begin
			    priority_first <= 1'b1;
		    end
		    else begin
			    priority_first <= 1'b0;
		    end
	    end
    end 
    assign grants = granted;
endmodule
