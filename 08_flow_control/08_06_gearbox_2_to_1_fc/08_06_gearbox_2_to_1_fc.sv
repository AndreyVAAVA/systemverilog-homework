//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_2_to_1_fc
# (
    parameter width = 8
)
(
    input                    clk,
    input                    rst,

    input                    up_valid,
    output                   up_ready,
    input   [ 2*width - 1:0] up_data,

    output                   down_valid,
    input                    down_ready,
    output  [   width - 1:0] down_data
);

    // Task:
    // Implement a module that generates tokens from of one token.
    // Example:
    // "0110" => "01", "10"
    //
    // The module must use signals valid-ready for transfer tokens.

    // Регистр для хранения полного входящего слова
    logic [2*width - 1 : 0] wide_reg;
    
    // Счетчик фазы выдачи: 0 - ожидание, 1 - выдача 1-й части, 2 - выдача 2-й части
    logic [1:0] phase;

    // --- Управление потоком (Flow Control) ---

    // Мы готовы принять новое широкое слово только когда полностью выдали предыдущее
    assign up_ready = (phase == 2'd0);

    // Выход валиден, если мы находимся в фазе выдачи (1 или 2)
    assign down_valid = (phase != 2'd0);

    // Выбор части данных для выхода согласно примеру:
    // "0110" -> "01" (MSB), затем "10" (LSB)
    assign down_data = (phase == 2'd1) ? wide_reg[2*width-1 : width] 
                                       : wide_reg[width-1 : 0];

    // --- Логика переключения состояний ---

    always_ff @(posedge clk) begin
        if (rst) begin
            phase    <= 2'd0;
            wide_reg <= '0;
        end else begin
            // 1. Прием данных от источника
            if (up_valid && up_ready) begin
                wide_reg <= up_data;
                phase    <= 2'd1;
            end 
            // 2. Выдача данных потребителю (Handshake на выходе)
            else if (down_valid && down_ready) begin
                if (phase == 2'd1) begin
                    // Переходим к выдаче второй части
                    phase <= 2'd2;
                end else begin
                    // Все выдано, возвращаемся в ожидание
                    phase <= 2'd0;
                end
            end
        end
    end
endmodule
