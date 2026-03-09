//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_impl_2_fsm
(
    input               clk,
    input               rst,

    input               arg_vld,
    input        [31:0] a,
    input        [31:0] b,
    input        [31:0] c,

    output logic        res_vld,
    output logic [31:0] res,

    // isqrt interface

    output logic        isqrt_1_x_vld,
    output logic [31:0] isqrt_1_x,

    input               isqrt_1_y_vld,
    input        [15:0] isqrt_1_y,

    output logic        isqrt_2_x_vld,
    output logic [31:0] isqrt_2_x,

    input               isqrt_2_y_vld,
    input        [15:0] isqrt_2_y
);

    // Task:
    // Implement a module that calculates the formula from the `formula_1_fn.svh` file
    // using two instances of the isqrt module in parallel.
    //
    // Design the FSM to calculate an answer and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm


    // FSM States
    enum logic [1:0]
    {
        st_idle        = 2'd0,
        st_wait_ab_res = 2'd1,
        st_wait_c_res  = 2'd2
    }
    state, next_state;

    // Next State Logic
    always_comb
    begin
        next_state = state;

        case (state)
            // Ждем входных данных, затем переходим к ожиданию результата A и B
            st_idle       : if ( arg_vld )       next_state = st_wait_ab_res;
            
            // Ждем завершения A и B (они заканчивают одновременно), затем ждем C
            st_wait_ab_res: if ( isqrt_1_y_vld ) next_state = st_wait_c_res;
            
            // Ждем завершения C, затем возвращаемся в Idle
            st_wait_c_res : if ( isqrt_1_y_vld ) next_state = st_idle;
        endcase
    end

    // State Register
    always_ff @ (posedge clk)
        if (rst)
            state <= st_idle;
        else
            state <= next_state;

    // Datapath Control (ISQRT Inputs)
    always_comb
    begin
        // Значения по умолчанию
        isqrt_1_x_vld = '0;
        isqrt_2_x_vld = '0;
        isqrt_1_x     = 'x; // Don't care
        isqrt_2_x     = 'x; // Don't care

        case (state)
            st_idle: 
            begin
                // Запускаем A на модуле 1 и B на модуле 2
                if (arg_vld) begin
                    isqrt_1_x_vld = 1'b1;
                    isqrt_1_x     = a;
                    
                    isqrt_2_x_vld = 1'b1;
                    isqrt_2_x     = b;
                end
            end

            st_wait_ab_res:
            begin
                // Как только A и B готовы, сразу запускаем C на модуле 1
                if (isqrt_1_y_vld) begin
                    isqrt_1_x_vld = 1'b1;
                    isqrt_1_x     = c;
                end
            end
            
            // В st_wait_c_res ничего запускать не нужно
        endcase
    end

    // Result Accumulation
    always_ff @ (posedge clk)
    begin
        if (state == st_idle) begin
            res <= '0;
        end
        else if (state == st_wait_ab_res && isqrt_1_y_vld) begin
            // Пришли результаты A и B (одновременно)
            // Суммируем их
            res <= isqrt_1_y + isqrt_2_y;
        end
        else if (state == st_wait_c_res && isqrt_1_y_vld) begin
            // Пришел результат C (на модуле 1)
            // Добавляем к общей сумме
            res <= res + isqrt_1_y;
        end
    end

    // Result Valid Output
    always_ff @ (posedge clk)
        if (rst)
            res_vld <= '0;
        else
            // Результат готов, когда мы в состоянии ожидания C и получили валидный сигнал
            res_vld <= (state == st_wait_c_res & isqrt_1_y_vld);
endmodule
