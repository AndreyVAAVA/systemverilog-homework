//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module float_discriminant (
    input                     clk,
    input                     rst,

    input                     arg_vld,
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,
    input        [FLEN - 1:0] c,

    output logic              res_vld,
    output logic [FLEN - 1:0] res,
    output logic              res_negative,
    output logic              err,

    output logic              busy
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs their discriminant.
    // The resulting value res should be calculated as a discriminant of the quadratic polynomial.
    // That is, res = b^2 - 4ac == b*b - 4*a*c
    //
    // Note:
    // If any argument is not a valid number, that is NaN or Inf, the "err" flag should be set.
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    localparam [FLEN - 1:0] four = 64'h4010_0000_0000_0000;

    // Состояния FSM
    enum logic [2:0] {
        st_idle     = 3'd0,
        st_calc_p1  = 3'd1, // Вычисление b*b и 4*a
        st_calc_p2  = 3'd2, // Вычисление (4*a) * c
        st_calc_res = 3'd3, // Вычисление (b*b) - (4*a*c)
        st_done     = 3'd4  // Выдача результата
    } state;

    // Внутренние регистры
    logic [FLEN - 1:0] r_a, r_b, r_c;
    logic [FLEN - 1:0] r_b_sq; // b^2
    logic [FLEN - 1:0] r_4a;   // 4a
    logic [FLEN - 1:0] r_4ac;  // 4ac
    logic [FLEN - 1:0] r_res;  // Результат
    logic              r_err;  // Аккумулятор ошибки

    // Сигналы (провода) от модулей
    logic [FLEN - 1:0] w_b_sq_res;
    logic [FLEN - 1:0] w_4a_res;
    logic [FLEN - 1:0] w_4ac_res;
    logic [FLEN - 1:0] w_sub_res;

    //------------------------------------------------------------------------
    // Функция проверки на NaN / Inf
    // Для FP64 (FLEN=64) экспонента находится в битах [62:52].
    // Если все биты экспоненты равны 1, то число - это Inf или NaN.
    //------------------------------------------------------------------------
    function automatic logic check_err(input [FLEN-1:0] val);
        return &val[62:52]; 
    endfunction

    //------------------------------------------------------------------------
    // Инстанцирование модулей
    // Добавляем clk и rst, так как отсутствие тактирования вызывает X (NaN).
    //------------------------------------------------------------------------

    // 1. b * b
    f_mult u_mult_b_sq (
        .clk ( clk        ), // Подключение клока
        .rst ( rst        ), // Подключение сброса
        .a   ( r_b        ),
        .b   ( r_b        ),
        .res ( w_b_sq_res )
    );

    // 2. 4 * a
    f_mult u_mult_4a (
        .clk ( clk        ),
        .rst ( rst        ),
        .a   ( four       ),
        .b   ( r_a        ),
        .res ( w_4a_res   )
    );

    // 3. (4a) * c
    f_mult u_mult_4ac (
        .clk ( clk        ),
        .rst ( rst        ),
        .a   ( r_4a       ),
        .b   ( r_c        ),
        .res ( w_4ac_res  )
    );

    // 4. (b^2) - (4ac)
    f_sub u_sub_final (
        .clk ( clk        ),
        .rst ( rst        ),
        .a   ( r_b_sq     ),
        .b   ( r_4ac      ),
        .res ( w_sub_res  )
    );

    //------------------------------------------------------------------------
    // FSM
    //------------------------------------------------------------------------

    assign busy = (state != st_idle);
    assign res  = r_res;
    assign err  = r_err;
    
    // Знак числа FP64 — это старший бит [63]
    assign res_negative = r_res[FLEN - 1]; 

    always_ff @(posedge clk) begin
        if (rst) begin
            state   <= st_idle;
            res_vld <= 1'b0;
            r_err   <= 1'b0;
            r_res   <= '0;
            
            // Сброс регистров данных
            r_a     <= '0;
            r_b     <= '0;
            r_c     <= '0;
            r_b_sq  <= '0;
            r_4a    <= '0;
            r_4ac   <= '0;
        end else begin
            case (state)
                st_idle: begin
                    res_vld <= 1'b0;
                    if (arg_vld) begin
                        r_a   <= a;
                        r_b   <= b;
                        r_c   <= c;
                        // Проверка входных аргументов
                        r_err <= check_err(a) | check_err(b) | check_err(c);
                        state <= st_calc_p1;
                    end
                end

                st_calc_p1: begin
                    // Защелкиваем результаты первого этапа
                    r_b_sq <= w_b_sq_res;
                    r_4a   <= w_4a_res;
                    
                    // Накапливаем ошибку
                    r_err  <= r_err | check_err(w_b_sq_res) | check_err(w_4a_res);
                    
                    state  <= st_calc_p2;
                end

                st_calc_p2: begin
                    // Защелкиваем результат второго этапа
                    r_4ac <= w_4ac_res;
                    
                    r_err <= r_err | check_err(w_4ac_res);
                    
                    state <= st_calc_res;
                end

                st_calc_res: begin
                    // Защелкиваем результат вычитания
                    r_res <= w_sub_res;
                    
                    r_err <= r_err | check_err(w_sub_res);
                    
                    state <= st_done;
                end

                st_done: begin
                    res_vld <= 1'b1;
                    state   <= st_idle;
                end
                
                default: state <= st_idle;
            endcase
        end
    end
endmodule
