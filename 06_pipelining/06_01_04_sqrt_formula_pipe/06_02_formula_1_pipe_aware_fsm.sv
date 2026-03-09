//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module formula_1_pipe_aware_fsm
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
    //
    // Implement a module formula_1_pipe_aware_fsm
    // with a Finite State Machine (FSM)
    // that drives the inputs and consumes the outputs
    // of a single pipelined module isqrt.
    //
    // The formula_1_pipe_aware_fsm module is supposed to be instantiated
    // inside the module formula_1_pipe_aware_fsm_top,
    // together with a single instance of isqrt.
    //
    // The resulting structure has to compute the formula
    // defined in the file formula_1_fn.svh.
    //
    // The formula_1_pipe_aware_fsm module
    // should NOT create any instances of isqrt module,
    // it should only use the input and output ports connecting
    // to the instance of isqrt at higher level of the instance hierarchy.
    //
    // All the datapath computations except the square root calculation,
    // should be implemented inside formula_1_pipe_aware_fsm module.
    // So this module is not a state machine only, it is a combination
    // of an FSM with a datapath for additions and the intermediate data
    // registers.
    //
    // Note that the module formula_1_pipe_aware_fsm is NOT pipelined itself.
    // It should be able to accept new arguments a, b and c
    // arriving at every N+3 clock cycles.
    //
    // In order to achieve this latency the FSM is supposed to use the fact
    // that isqrt is a pipelined module.
    //
    // For more details, see the discussion of this problem
    // in the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

	// Состояния конечного автомата
    typedef enum logic [1:0] {
        IDLE    = 2'b00,
        FEED_B  = 2'b01,
        FEED_C  = 2'b10,
        COLLECT = 2'b11
    } state_e;

    state_e state;

    // Регистры для хранения входных данных и промежуточной суммы
    logic [31:0] b_reg, c_reg;
    logic [31:0] sum_acc;
    logic [1:0]  res_cnt; // Счетчик полученных результатов (нужно 3)

    // Логика FSM и управления данными
    always_ff @(posedge clk) begin
        if (rst) begin
            state       <= IDLE;
            isqrt_x_vld <= 1'b0;
            isqrt_x     <= 32'b0;
            res_vld     <= 1'b0;
            res         <= 32'b0;
            res_cnt     <= 2'b0;
            sum_acc     <= 32'b0;
        end else begin
            // По умолчанию сбрасываем флаг готовности результата
            res_vld <= 1'b0;

            case (state)
                IDLE: begin
                    if (arg_vld) begin
                        // Сразу отправляем 'a' в конвейер isqrt
                        isqrt_x_vld <= 1'b1;
                        isqrt_x     <= a;
                        // Сохраняем остальные аргументы
                        b_reg       <= b;
                        c_reg       <= c;
                        sum_acc     <= 32'b0;
                        res_cnt     <= 2'b0;
                        state       <= FEED_B;
                    end else begin
                        isqrt_x_vld <= 1'b0;
                    end
                end

                FEED_B: begin
                    // Отправляем 'b' в следующем такте
                    isqrt_x_vld <= 1'b1;
                    isqrt_x     <= b_reg;
                    state       <= FEED_C;
                end

                FEED_C: begin
                    // Отправляем 'c'
                    isqrt_x_vld <= 1'b1;
                    isqrt_x     <= c_reg;
                    state       <= COLLECT;
                end

                COLLECT: begin
                    isqrt_x_vld <= 1'b0; // Перестаем подавать данные
                    
                    // Ждем и собираем 3 результата из конвейера
                    if (isqrt_y_vld) begin
                        if (res_cnt == 2'b10) begin // Пришел 3-й результат
                            res     <= sum_acc + 32'(isqrt_y);
                            res_vld <= 1'b1;
                            state   <= IDLE;
                        end else begin
                            sum_acc <= sum_acc + 32'(isqrt_y);
                            res_cnt <= res_cnt + 1'b1;
                        end
                    end
                end
            endcase
        end
    end

endmodule
