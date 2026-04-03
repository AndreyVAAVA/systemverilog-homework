module a_plus_b_using_double_buffers
# (
    parameter width = 8
)
(
    input                clk,
    input                rst,

    input                a_valid,
    output               a_ready,
    input  [width - 1:0] a_data,

    input                b_valid,
    output               b_ready,
    input  [width - 1:0] b_data,

    output               sum_valid,
    input                sum_ready,
    output [width - 1:0] sum_data
);

    //------------------------------------------------------------------------

    wire               a_down_valid;
    wire               a_down_ready;
    wire [width - 1:0] a_down_data;

    double_buffer_from_dally_harting
    # (.width (width))
    buffer_a
    (
        .clk         ( clk          ),
        .rst         ( rst          ),

        .up_valid    ( a_valid      ),
        .up_ready    ( a_ready      ),
        .up_data     ( a_data       ),

        .down_valid  ( a_down_valid ),
        .down_ready  ( a_down_ready ),
        .down_data   ( a_down_data  )
    );

    //------------------------------------------------------------------------

    wire               b_down_valid;
    wire               b_down_ready;
    wire [width - 1:0] b_down_data;

    double_buffer_from_dally_harting
    # (.width (width))
    buffer_b
    (
        .clk         ( clk          ),
        .rst         ( rst          ),

        .up_valid    ( b_valid      ),
        .up_ready    ( b_ready      ),
        .up_data     ( b_data       ),

        .down_valid  ( b_down_valid ),
        .down_ready  ( b_down_ready ),
        .down_data   ( b_down_data  )
    );

    //------------------------------------------------------------------------

    // Task: Add logic using the template below
    //
    // wire               sum_up_valid = ...
    // wire               sum_up_ready;
    // wire [width - 1:0] sum_up_data  = ...
    //
    // assign a_down_ready = ...
    // assign b_down_ready = ...

	// 1. Объявляем сигналы (убедитесь, что они раскомментированы в шаблоне)
    wire                  sum_up_valid;
    wire                  sum_up_ready; // Сигнал готовности от выходного буфера
    wire [width - 1 : 0]  sum_up_data;

    // 2. Внутренние защелки для слагаемых
    logic                 v_a, v_b;         // Флаги занятости защелок
    logic [width - 1 : 0] d_a, d_b;         // Регистры данных

    // 3. Формирование сигналов для выходного буфера
    // СУММА ВАЛИДНА ТОЛЬКО КОГДА ОБЕ ЗАЩЕЛКИ ПОЛНЫ
    assign sum_up_valid = v_a & v_b;
    // СУММА ВЫЧИСЛЯЕТСЯ ТОЛЬКО ИЗ ЗАРЕГИСТРИРОВАННЫХ ДАННЫХ
    assign sum_up_data  = d_a + d_b;

    // 4. Вспомогательные сигналы рукопожатий (Handshakes)
    wire handshake_a   = a_down_valid & a_down_ready;
    wire handshake_b   = b_down_valid & b_down_ready;
    wire handshake_sum = sum_up_valid & sum_up_ready;

    // 5. Логика готовности (Ready):
    // Мы готовы принять данные из A, если защелка A пуста ИЛИ если она сейчас освобождается
    assign a_down_ready = !v_a | handshake_sum;
    assign b_down_ready = !v_b | handshake_sum;

    // 6. Обновление состояния в блоке FF
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            v_a <= 1'b0;
            v_b <= 1'b0;
            d_a <= '0;
            d_b <= '0;
        end else begin
            // Логика защелки A:
            // Становится полной, если мы приняли данные (handshake_a)
            // Становится пустой, если сумма ушла (handshake_sum)
            // Если произошло и то, и другое — остается полной (приняли следующее значение)
            v_a <= handshake_a | (v_a & !handshake_sum);
            
            // Логика защелки B (аналогично):
            v_b <= handshake_b | (v_b & !handshake_sum);

            // Сохраняем данные при успешном рукопожатии на входе
            if (handshake_a) d_a <= a_down_data;
            if (handshake_b) d_b <= b_down_data;
        end
    end
	
    //------------------------------------------------------------------------

    double_buffer_from_dally_harting
    # (.width (width))
    buffer_sum
    (
        .clk         ( clk          ),
        .rst         ( rst          ),

        .up_valid    ( sum_up_valid ),
        .up_ready    ( sum_up_ready ),
        .up_data     ( sum_up_data  ),

        .down_valid  ( sum_valid    ),
        .down_ready  ( sum_ready    ),
        .down_data   ( sum_data     )
    );

endmodule
