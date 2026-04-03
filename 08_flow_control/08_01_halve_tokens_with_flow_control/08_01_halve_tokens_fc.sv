//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module halve_tokens_with_flow_control
(
    input  clk,
    input  rst,

    input  up_valid,
    output up_ready,
    input  up_token,

    output down_valid,
    input  down_ready,
    output down_data
);

    // Task:
    // Implement a serial module that reduces amount of incoming '1' tokens by half.
    // The module must use the ready-valid protocol.
    //
    //  Expected behavior of the module
    //  1) When the input signals are up_token and up_valid is high, the signal (token) is processed.
    //  2) Every second signal received for processing is sent to the output of the module.
    //  3) When the module cannot process the signal, it sets the up_ready signal to a low level.
    //
    // Example:
    // down_ready     ->   1111_1111_1111_0000
    // up_token       ->   1101_0100_1111_1111
    // up_valid       ->   1111_1111_0101_1111
    // down_valid     ->   1111_1111_1111_1000
    // down_data      ->   0100_0100_0001_0000
    // up_ready       ->   1111_1111_0101_1000

    logic state_reg;      // Состояние
    logic is_even_token;  // Флаг, что текущая '1' — вторая в паре
    logic transfer_en;    // Сигнал успешного такта

    // Логика определения второй единицы
    assign is_even_token = up_token & state_reg;
    
    // Условие передачи данных на входе
    assign transfer_en   = up_valid & up_ready;

    // Работа с регистром состояния
    always_ff @ (posedge clk) begin
        if (rst) begin
            state_reg <= 1'b0;
        end else if (transfer_en & up_token) begin
            state_reg <= ~state_reg;
        end
    end

    assign down_valid = up_valid;
	
    // Данные '1' выдаются только если это вторая единица в паре и все готовы
    assign down_data  = up_valid & is_even_token & down_ready;
    
    // Готовность принимать (если потребитель готов ИЛИ если текущий токен нам не нужен (нужно его отбросить))
    assign up_ready   = up_valid & (down_ready | ~is_even_token);

endmodule
