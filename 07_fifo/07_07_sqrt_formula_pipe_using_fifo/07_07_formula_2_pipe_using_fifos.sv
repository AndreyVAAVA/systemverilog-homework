//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe_using_fifos
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
    // Implement a pipelined module formula_2_pipe_using_fifos that computes the result
    // of the formula defined in the file formula_2_fn.svh.
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
    // 3. Your solution should use FIFOs instead of shift registers
    // which were used in 06_04_formula_2_pipe.sv.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

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

    // FIFO для аргумента 'b' (задержка N)
    wire [31:0] b_from_fifo;
    flip_flop_fifo_with_counter #(.width(32), .depth(latency)) i_fifo_b (
        .clk       ( clk         ),
        .rst       ( rst         ),
        .push      ( arg_vld     ), // Пишем, когда пришли входные данные
        .pop       ( sqrt_c_vld  ), // Читаем, когда готов результат первого корня
        .write_data( b           ),
        .read_data ( b_from_fifo ),
        .empty     ( ), .full ( )
    );

    // FIFO для аргумента 'a' (задержка 2*N)
    wire [31:0] a_from_fifo;
    flip_flop_fifo_with_counter #(.width(32), .depth(2 * latency)) i_fifo_a (
        .clk       ( clk         ),
        .rst       ( rst         ),
        .push      ( arg_vld     ), // Пишем в самом начале
        .pop       ( sqrt_bc_vld ), // Читаем только когда готов результат ВТОРОГО корня
        .write_data( a           ),
        .read_data ( a_from_fifo ),
        .empty     ( ), .full ( )
    );

    // --- Слой 2: sqrt(b + sqrt(c)) ---
    wire [31:0] sqrt_bc_res;
    wire        sqrt_bc_vld;

    isqrt #(.n_pipe_stages(latency)) i_isqrt_2 (
        .clk   ( clk             ),
        .rst   ( rst             ),
        .x_vld ( sqrt_c_vld      ),
        .x     ( b_from_fifo + sqrt_c_res ),
        .y_vld ( sqrt_bc_vld     ),
        .y     ( sqrt_bc_res     )
    );

    // --- Слой 3: sqrt(a + sqrt(b + sqrt(c))) ---
    isqrt #(.n_pipe_stages(latency)) i_isqrt_3 (
        .clk   ( clk             ),
        .rst   ( rst             ),
        .x_vld ( sqrt_bc_vld     ),
        .x     ( a_from_fifo + sqrt_bc_res ),
        .y_vld ( res_vld         ),
        .y     ( res             )
    );
endmodule
