//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module gearbox_1_to_2_fc
# (
    parameter width = 8
)
(
    input                   clk,
    input                   rst,
    input                   up_valid,
    output                  up_ready,
    input  [   width - 1:0] up_data,
    output                  down_valid,
    output [ 2*width - 1:0] down_data,
    input                   down_ready
);

    // Task:
    // Implement a module that generates one token from of two tokens.
    // Example:
    // "01", "10" => "0110"
    //
    // The module must use signals valid-ready for transfer tokens.

    // Внутренний накопитель для двух слов
    logic [2*width - 1 : 0] storage;
    // Счетчик количества слов в буфере: 0, 1 или 2
    logic [1:0] occupancy;

    // Статус транзакций (рукопожатий)
    wire rx_active = up_valid & up_ready;
    wire tx_active = down_valid & down_ready;

    // Мы готовы принимать данные, если в буфере есть место (0 или 1 слово) ИЛИ если прямо сейчас потребитель забирает готовый результат из буфера.
    assign up_ready   = (occupancy < 2'd2) || down_ready;

    // Выход валиден ТОЛЬКО когда в буфере накоплено ровно 2 слова
    assign down_valid = (occupancy == 2'd2);
    assign down_data  = storage;

    always_ff @(posedge clk) begin
        if (rst) begin
            occupancy <= 2'd0;
            storage   <= '0;
        end else begin
            case ({rx_active, tx_active})
                // Ситуация 1: Только прием данных (RX)
                2'b10: begin
                    occupancy <= occupancy + 1'b1;
                    if (occupancy == 2'd0)
                        // Первое слово кладем в старшую часть
                        storage[2*width-1 : width] <= up_data;
                    else
                        // Второе слово кладем в младшую часть
                        storage[width-1 : 0] <= up_data;
                end

                // Ситуация 2: Только выдача данных (TX)
                2'b01: begin
                    // После выдачи буфер полностью пустеет
                    occupancy <= 2'd0;
                    storage   <= '0; // Очистка для предотвращения ошибок "мусора"
                end

                // Ситуация 3: Одновременный прием и выдача (RX + TX)
                // Это возможно только когда occupancy == 2. Мы отдаем старую пару
                // и сразу записываем входящий up_data как первое слово новой пары.
                2'b11: begin
                    occupancy <= 2'd1;
                    storage   <= {up_data, {width{1'b0}}};
                end

                default: ; // Состояние не меняется
            endcase
        end
    end
	
endmodule
