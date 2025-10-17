//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module mux
(
  input  d0, d1,
  input  sel,
  output y
);

  assign y = sel ? d1 : d0;

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module xor_gate_using_mux
(
    input  a,
    input  b,
    output o
);

  // Task:
  // Implement xor gate using instance(s) of mux,
  // constants 0 and 1, and wire connections

  // ver. 1
  //wire temp_1, temp_2;
  //mux mux_1(0, b, a, temp_1); // AND gate
  //mux mux_2(b, 1, a, temp_2); // OR gate
  //mux mux_3(temp_2, 0, temp_1, o);

  //ver. 2
  mux mux_1(b, ~b, a, o);
endmodule
