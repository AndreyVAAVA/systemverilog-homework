//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_pipe
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
    // Implement a pipelined module formula_2_pipe that computes the result
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
    // 3. Your solution should save dynamic power by properly connecting
    // the valid bits.
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

	    parameter int N = 16; // Латентность модуля isqrt

    // --- СТАДИЯ 1: Вычисляем sqrt(c) и задерживаем b ---
    wire [15:0] sqrt_c;
    wire        vld_1;
    wire [31:0] b_delayed;
    wire        vld_b_delayed;

    isqrt i_isqrt_1 (
        .clk(clk), .rst(rst), 
        .x_vld(arg_vld), .x(c), 
        .y_vld(vld_1), .y(sqrt_c)
    );

    shift_register_with_valid #(.width(32), .depth(N)) i_shift_b (
        .clk(clk), .rst(rst),
        .in_vld(arg_vld), .in_data(b),
        .out_vld(vld_b_delayed), .out_data(b_delayed)
    );

    // --- СТАДИЯ 2: Сумма (b + sqrt(c)) и регистр (1 такт) ---
    reg [31:0] sum_1_reg;
    reg        vld_sum_1;

    always @(posedge clk) begin
        if (rst) vld_sum_1 <= 1'b0;
        else     vld_sum_1 <= vld_1;

        if (vld_1) sum_1_reg <= b_delayed + 32'(sqrt_c);
    end

    // --- СТАДИЯ 3: Вычисляем sqrt(b + sqrt(c)) и задерживаем a ---
    wire [15:0] sqrt_bc;
    wire        vld_2;
    wire [31:0] a_delayed;
    wire        vld_a_delayed;

    isqrt i_isqrt_2 (
        .clk(clk), .rst(rst), 
        .x_vld(vld_sum_1), .x(sum_1_reg), 
        .y_vld(vld_2), .y(sqrt_bc)
    );

    // Задержка для 'a' должна быть 2*N + 1 тактов 
    // (N для первого корня, 1 для регистра суммы, N для второго корня — нет, 
    // согласно схеме нужно 2N+1 чтобы встретиться с выходом второго корня)
    shift_register_with_valid #(.width(32), .depth(2*N + 1)) i_shift_a (
        .clk(clk), .rst(rst),
        .in_vld(arg_vld), .in_data(a),
        .out_vld(vld_a_delayed), .out_data(a_delayed)
    );

    // --- СТАДИЯ 4: Сумма (a + sqrt(b + sqrt(c))) и регистр (1 такт) ---
    reg [31:0] sum_2_reg;
    reg        vld_sum_2;

    always @(posedge clk) begin
        if (rst) vld_sum_2 <= 1'b0;
        else     vld_sum_2 <= vld_2;

        if (vld_2) sum_2_reg <= a_delayed + 32'(sqrt_bc);
    end

    // --- СТАДИЯ 5: Финальный корень ---
    isqrt i_isqrt_3 (
        .clk(clk), .rst(rst), 
        .x_vld(vld_sum_2), .x(sum_2_reg), 
        .y_vld(res_vld),   .y(res[15:0]) // результат 16 бит, расширяем до 32
    );

    assign res[31:16] = 16'b0;
	
endmodule
