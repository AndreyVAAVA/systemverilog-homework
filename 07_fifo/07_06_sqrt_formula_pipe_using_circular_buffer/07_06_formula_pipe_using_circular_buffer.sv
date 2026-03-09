//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe_using_circular
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);

    // Task:
    //
    // Implement a pipelined module formula_2_pipe_using_circular
    // that computes the result of the formula defined in the file formula_2_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_2_pipe has to be pipelined.
    //
    // It should be able to accept a new set of arguments a, b and c
    // arriving at every clock cycle.
    //
    // It also should be able to produce a new result every clock cycle
    // with a fixed latency after accepting the arguments.
    //
    // 2. Your solution should instantiate exactly 3 instances
    // of a pipelined isqrt module, which computes the integer square root.
    //
    // 3. Your solution should use circular buffers instead of shift registers
    // which were used in 06_04_formula_2_pipe.sv.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

    localparam latency = 16; 

    // --- Слой 1: sqrt(c) ---
    wire [31:0] sqrt_c_res;
    wire        sqrt_c_vld;

    isqrt #(.n_pipe_stages(latency)) i_isqrt_1 (
        .clk   ( clk        ),
        .rst   ( rst        ),
        .x_vld ( arg_vld    ),
        .x     ( c          ),
        .y_vld ( sqrt_c_vld ),
        .y     ( sqrt_c_res )
    );

    wire [31:0] b_delayed;
    wire        b_vld;
    circular_buffer_with_valid #(.width(32), .depth(latency)) i_buf_b (
        .clk      ( clk     ),
        .rst      ( rst     ),
        .in_valid ( arg_vld ),
        .in_data  ( b       ),
        .out_valid( b_vld   ),
        .out_data ( b_delayed )
    );

    wire [31:0] a_st1_delayed;
    wire        a_st1_vld;
    circular_buffer_with_valid #(.width(32), .depth(latency)) i_buf_a_st1 (
        .clk      ( clk           ),
        .rst      ( rst           ),
        .in_valid ( arg_vld       ),
        .in_data  ( a             ),
        .out_valid( a_st1_vld     ),
        .out_data ( a_st1_delayed )
    );

    // --- Слой 2: sqrt(b + sqrt(c)) ---
    wire [31:0] sqrt_bc_res;
    wire        sqrt_bc_vld;

    isqrt #(.n_pipe_stages(latency)) i_isqrt_2 (
        .clk   ( clk             ),
        .rst   ( rst             ),
        .x_vld ( sqrt_c_vld      ),
        .x     ( b_delayed + sqrt_c_res ),
        .y_vld ( sqrt_bc_vld     ),
        .y     ( sqrt_bc_res     )
    );

    wire [31:0] a_st2_delayed;
    wire        a_st2_vld;
    circular_buffer_with_valid #(.width(32), .depth(latency)) i_buf_a_st2 (
        .clk      ( clk           ),
        .rst      ( rst           ),
        .in_valid ( a_st1_vld     ),
        .in_data  ( a_st1_delayed ),
        .out_valid( a_st2_vld     ),
        .out_data ( a_st2_delayed )
    );

    // --- Слой 3: sqrt(a + sqrt(b + sqrt(c))) ---
    isqrt #(.n_pipe_stages(latency)) i_isqrt_3 (
        .clk   ( clk             ),
        .rst   ( rst             ),
        .x_vld ( sqrt_bc_vld     ),
        .x     ( a_st2_delayed + sqrt_bc_res ),
        .y_vld ( res_vld         ),
        .y     ( res             )
    );
endmodule
