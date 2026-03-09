//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe
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
    // Implement a pipelined module formula_1_pipe that computes the result
    // of the formula defined in the file formula_1_fn.svh.
    //
    // The requirements:
    //
    // 1. The module formula_1_pipe has to be pipelined.
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


    // Промежуточные сигналы для результатов (16 бит) и флагов валидности
    wire [15:0] res_a, res_b, res_c;
    wire        vld_a, vld_b, vld_c;

    // 1. Инстанцируем 3 экземпляра модуля isqrt с правильными именами портов
    isqrt i_isqrt_a (
        .clk   ( clk     ),
        .rst   ( rst     ),
        .x_vld ( arg_vld ),
        .x     ( a       ),
        .y_vld ( vld_a   ),
        .y     ( res_a   )
    );

    isqrt i_isqrt_b (
        .clk   ( clk     ),
        .rst   ( rst     ),
        .x_vld ( arg_vld ),
        .x     ( b       ),
        .y_vld ( vld_b   ),
        .y     ( res_b   )
    );

    isqrt i_isqrt_c (
        .clk   ( clk     ),
        .rst   ( rst     ),
        .x_vld ( arg_vld ),
        .x     ( c       ),
        .y_vld ( vld_c   ),
        .y     ( res_c   )
    );

    // 2. Реализация логики согласно архитектурной диаграмме
    
    reg [31:0] res_reg;
    reg        res_vld_reg;

    // Оранжевый блок на диаграмме: Регистр валидности
    always @(posedge clk) begin
        if (rst)
            res_vld_reg <= 1'b0;
        else
            res_vld_reg <= vld_a; // Все конвейеры одинаковы, берем любой vld
    end

    // Зеленый блок на диаграмме: Сумматор и регистр данных с Enable
    // Условие 'if (vld_a)' экономит динамическую мощность (Clock Enable)
    always @(posedge clk) begin
        if (vld_a) begin
            // Складываем 16-битные значения, расширяя их до 32 бит
            res_reg <= 32'(res_a) + 32'(res_b) + 32'(res_c);
        end
    end

    assign res     = res_reg;
    assign res_vld = res_vld_reg;
	
endmodule
