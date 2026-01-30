//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_2_fsm
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

    output logic        isqrt_x_vld,
    output logic [31:0] isqrt_x,

    input               isqrt_y_vld,
    input        [15:0] isqrt_y
);
    // Task:
    // Implement a module that calculates the formula from the `formula_2_fn.svh` file
    // using only one instance of the isqrt module.
    //
    // Design the FSM to calculate answer step-by-step and provide the correct `res` value
    //
    // You can read the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm

    // FSM States
    enum logic [1:0]
    {
        st_idle   = 2'd0, // Ждем старта, запускаем sqrt(c)
        st_wait_1 = 2'd1, // Ждем sqrt(c), запускаем sqrt(b + res)
        st_wait_2 = 2'd2, // Ждем sqrt(b + ...), запускаем sqrt(a + res)
        st_wait_3 = 2'd3  // Ждем финальный результат
    }
    state, next_state;

    // Next State Logic
    always_comb
    begin
        next_state = state;

        case (state)
            st_idle   : if ( arg_vld     ) next_state = st_wait_1;
            st_wait_1 : if ( isqrt_y_vld ) next_state = st_wait_2;
            st_wait_2 : if ( isqrt_y_vld ) next_state = st_wait_3;
            st_wait_3 : if ( isqrt_y_vld ) next_state = st_idle;
        endcase
    end

    // State Register
    always_ff @ (posedge clk)
        if (rst)
            state <= st_idle;
        else
            state <= next_state;

    // Datapath Control (ISQRT Inputs)
    // Мы мультиплексируем входы в модуль isqrt в зависимости от стадии вычисления
    always_comb
    begin
        isqrt_x_vld = '0;
        isqrt_x     = 'x; // Don't care по умолчанию

        case (state)
            st_idle:
            begin
                // Шаг 1: Вычисляем sqrt(c)
                if (arg_vld) begin
                    isqrt_x_vld = 1'b1;
                    isqrt_x     = c;
                end
            end

            st_wait_1:
            begin
                // Шаг 2: Пришел результат sqrt(c). 
                // Сразу запускаем sqrt(b + результат)
                if (isqrt_y_vld) begin
                    isqrt_x_vld = 1'b1;
                    isqrt_x     = b + isqrt_y;
                end
            end

            st_wait_2:
            begin
                // Шаг 3: Пришел результат sqrt(b + sqrt(c)).
                // Сразу запускаем sqrt(a + результат)
                if (isqrt_y_vld) begin
                    isqrt_x_vld = 1'b1;
                    isqrt_x     = a + isqrt_y;
                end
            end
            
            // В st_wait_3 мы просто ждем ответ, ничего запускать не нужно.
        endcase
    end

    // Result Logic
    always_ff @ (posedge clk)
        if (rst)
            res_vld <= '0;
        else
            // Результат валиден, когда мы в последней стадии и модуль isqrt выдал ответ
            res_vld <= (state == st_wait_3 & isqrt_y_vld);

    always_ff @ (posedge clk)
    begin
        // Если мы в последней стадии и данные готовы, записываем ответ
        if (state == st_wait_3 && isqrt_y_vld)
            res <= isqrt_y; // Автоматическое расширение до 32 бит
        
        // Опционально: очистка результата в idle, хотя это не строго обязательно
        if (state == st_idle)
            res <= '0;
    end

endmodule
