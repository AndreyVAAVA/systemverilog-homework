//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module detect_4_bit_sequence_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  output detected
);

  // Detection of the "1010" sequence

  // States (F — First, S — Second)
  enum logic[2:0]
  {
     IDLE = 3'b000,
     F1   = 3'b001,
     F0   = 3'b010,
     S1   = 3'b011,
     S0   = 3'b100
  }
  state, new_state;

  // State transition logic
  always_comb
  begin
    new_state = state;

    // This lint warning is bogus because we assign the default value above
    // verilator lint_off CASEINCOMPLETE

    case (state)
      IDLE: if (  a) new_state = F1;
      F1:   if (~ a) new_state = F0;
      F0:   if (  a) new_state = S1;
            else     new_state = IDLE;
      S1:   if (~ a) new_state = S0;
            else     new_state = F1;
      S0:   if (  a) new_state = S1;
            else     new_state = IDLE;
    endcase

    // verilator lint_on CASEINCOMPLETE

  end

  // Output logic (depends only on the current state)
  assign detected = (state == S0);

  // State update
  always_ff @ (posedge clk)
    if (rst)
      state <= IDLE;
    else
      state <= new_state;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module detect_6_bit_sequence_using_fsm
(
  input  clk,
  input  rst,
  input  a,
  output detected
);

  // Task:
  // Implement a module that detects the "110011" input sequence
  //
  // Hint: See Lecture 3 for details


  enum logic[3:0]
  {
     IDLE = 4'b0000,
     F1   = 4'b0001,
     F0   = 4'b0010,
     S1   = 4'b0011,
     S0   = 4'b0100,
     T1   = 4'b0101,
     T0  = 4'b0110
  } state, new_state;

  always_comb begin
		new_state = state;
		case (state)
			IDLE: begin if (a)
			new_state = F1;
			end
			F1: begin if (a) new_state = F0;
			else   new_state = IDLE;
			end
			F0: begin if (~a) new_state = S1;
			else    new_state = F1;
			end
			S1: begin if (!a) new_state = S0;
			else    new_state = F1;
			end
			S0: begin if (a) new_state = T1;
			else   new_state = IDLE;
			end
			T1: begin if (a) new_state = T0;
			else   new_state = IDLE;
			end
			T0: begin if (a) new_state = F0;
			else   new_state = S1;
			end
		endcase
  end

  assign detected = (state == T0);

  always_ff @ (posedge clk)
    if (rst)
      state <= IDLE;
    else
      state <= new_state;
endmodule
