//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module double_tokens_with_flow_control
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
  // Implement module double input signals (tokens). The module must use signals valid-ready for
  // transfer tokens. If the module receives more than 100 sequential tokens then it must set up_ready = 0;

    logic [8:0] ones_debt;      // Сколько единиц осталось выдать (9 бит с запасом)
    logic [6:0] burst_cnt;      // Счетчик входящих токенов при заблокированном выходе
    logic       limit_active;   // Флаг превышения лимита в 100 токенов

    // Вспомогательные сигналы для рукопожатий
    logic rx_done;
    logic tx_done;

    // 1. Логика управления входной готовностью (up_ready)
    // Если лимит превышен, мы готовы принимать новые данные только если выход свободен
    assign up_ready = limit_active ? down_ready : 1'b1;

    // Мы приняли токен '1', если все сигналы интерфейса активны
    assign rx_done = up_valid & up_ready & up_token;

    // 2. Логика выходных сигналов
    // В данном типе задач down_valid часто всегда 1, а данные зависят от наличия токенов
    assign down_valid = 1'b1;
    
    // Выдаем '1', если у нас есть "долг" по единицам или если '1' пришла прямо сейчас
    assign down_data = (ones_debt != 9'd0) | rx_done;

    // Успешная передача '1' потребителю
    assign tx_done = down_valid & down_ready & down_data;

    // 3. Основной блок управления состоянием
    always_ff @(posedge clk) begin
        if (rst) begin
            ones_debt    <= '0;
            burst_cnt    <= '0;
            limit_active <= 1'b0;
        end else begin
            // Управление счетчиком "долга" единиц:
            // +2 если приняли токен, -1 если успешно отдали единицу
            ones_debt <= ones_debt 
                       + (rx_done ? 9'd2 : 9'd0) 
                       - (tx_done ? 9'd1 : 9'd0);

            // Управление счетчиком последовательных токенов (streak)
            if (down_ready) begin
                burst_cnt <= '0; // Сбрасываем, если потребитель начал принимать
            end else if (rx_done) begin
                if (burst_cnt < 7'd120) 
                    burst_cnt <= burst_cnt + 7'd1;
            end

            // Логика блокировки (Stall logic)
            // Если набрали 100 токенов в буфер при закрытом выходе — включаем лимит
            if (~limit_active && ~down_ready && rx_done && (burst_cnt == 7'd99)) begin
                limit_active <= 1'b1;
            end 
            // Выключаем лимит, когда полностью разгрузили очередь (как в примере)
            else if (limit_active && (ones_debt == 9'd0)) begin
                limit_active <= 1'b0;
            end
        end
    end

endmodule
