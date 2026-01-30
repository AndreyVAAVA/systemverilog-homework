//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_floats_using_fsm (
    input                          clk,
    input                          rst,

    input                          valid_in,
    input        [0:2][FLEN - 1:0] unsorted,

    output logic                   valid_out,
    output logic [0:2][FLEN - 1:0] sorted,
    output logic                   err,
    output                         busy,

    // f_less_or_equal interface
    output logic      [FLEN - 1:0] f_le_a,
    output logic      [FLEN - 1:0] f_le_b,
    input                          f_le_res,
    input                          f_le_err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order using FSM.
    //
    // Requirements:
    // The solution must have latency equal to the three clock cycles.
    // The solution should use the inputs and outputs to the single "f_less_or_equal" module.
    // The solution should NOT create instances of any modules.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res1
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    // Внутренние регистры для хранения чисел в процессе сортировки
    logic [0:2][FLEN - 1:0] regs;
    // Регистр ошибки
    logic                   reg_err;

    // Состояния FSM
    enum logic [2:0] {
        st_idle       = 3'd0,
        st_comp_01_a  = 3'd1, // Первое сравнение: [0] и [1]
        st_comp_12    = 3'd2, // Второе сравнение: [1] и [2]
        st_comp_01_b  = 3'd3, // Третье сравнение: [0] и [1] (финальное)
        st_done       = 3'd4  // Выдача результата
    } state;

    // Подключение выходов
    assign sorted = regs;
    assign err    = reg_err;
    assign busy   = (state != st_idle);

    //------------------------------------------------------------------------
    // Управление мультиплексором для модуля сравнения (Combinational)
    //------------------------------------------------------------------------
    always_comb begin
        // Значения по умолчанию
        f_le_a = '0;
        f_le_b = '0;

        case (state)
            st_comp_01_a, st_comp_01_b: begin
                f_le_a = regs[0];
                f_le_b = regs[1];
            end
            st_comp_12: begin
                f_le_a = regs[1];
                f_le_b = regs[2];
            end
            default: begin
                f_le_a = 'x;
                f_le_b = 'x;
            end
        endcase
    end

    //------------------------------------------------------------------------
    // Логика переходов и обновления данных (Sequential)
    //------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (rst) begin
            state     <= st_idle;
            valid_out <= 1'b0;
            reg_err   <= 1'b0;
            regs      <= '0;
        end else begin
            case (state)
                st_idle: begin
                    valid_out <= 1'b0;
                    if (valid_in) begin
                        regs    <= unsorted;
                        state   <= st_comp_01_a;
                        reg_err <= 1'b0;
                    end
                end

                st_comp_01_a: begin
                    if (f_le_err) begin
                        reg_err <= 1'b1;
                        state   <= st_done;
                    end else begin
                        // Если regs[0] > regs[1] (то есть NOT less_or_equal), меняем местами
                        if (!f_le_res) begin
                            regs[0] <= regs[1];
                            regs[1] <= regs[0];
                        end
                        state <= st_comp_12;
                    end
                end

                st_comp_12: begin
                    if (f_le_err) begin
                        reg_err <= 1'b1;
                        state   <= st_done;
                    end else begin
                        // Если regs[1] > regs[2], меняем местами
                        if (!f_le_res) begin
                            regs[1] <= regs[2];
                            regs[2] <= regs[1];
                        end
                        state <= st_comp_01_b;
                    end
                end

                st_comp_01_b: begin
                    if (f_le_err) begin
                        reg_err <= 1'b1;
                    end else begin
                        // Финальная проверка regs[0] и regs[1]
                        if (!f_le_res) begin
                            regs[0] <= regs[1];
                            regs[1] <= regs[0];
                        end
                    end
                    // В любом случае (даже если ошибка) переходим в done на следующем такте
                    state <= st_done;
                end

                st_done: begin
                    valid_out <= 1'b1;
                    state     <= st_idle;
                end
            endcase
        end
    end

endmodule
