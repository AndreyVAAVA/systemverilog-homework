module put_in_order
# (
    parameter width    = 16,
              n_inputs = 4
)
(
    input                       clk,
    input                       rst,

    input  [ n_inputs - 1 : 0 ] up_vlds,
    input  [ n_inputs - 1 : 0 ]
           [ width    - 1 : 0 ] up_data,

    output                      down_vld,
    output [ width   - 1 : 0 ]  down_data
);

    // Task:
    //
    // Implement a module that accepts many outputs of the computational blocks
    // and outputs them one by one in order. Input signals "up_vlds" and "up_data"
    // are coming from an array of non-pipelined computational blocks.
    // These external computational blocks have a variable latency.
    //
    // The order of incoming "up_vlds" is not determent, and the task is to
    // output "down_vld" and corresponding data in a round-robin manner,
    // one after another, in order.
    //
    // Comment:
    // The idea of the block is kinda similar to the "parallel_to_serial" block
    // from Homework 2, but here block should also preserve the output order.

    // Буфер для хранения данных
    logic [width - 1 : 0] storage [n_inputs];
    
    // Маска готовности данных в буфере
    logic [n_inputs - 1 : 0] ready;
    
    // Указатель на текущий ожидаемый индекс
    logic [$clog2(n_inputs) - 1 : 0] out_ptr;

    // Внутренние регистры для выходов
    logic                    down_vld_r;
    logic [width - 1 : 0]    down_data_r;

    always_ff @(posedge clk) begin
        if (rst) begin
            ready       <= '0;
            out_ptr     <= '0;
            down_vld_r  <= 1'b0;
            down_data_r <= '0;
        end else begin
            // 1. Прием данных от всех входных модулей
            for (int i = 0; i < n_inputs; i++) begin
                if (up_vlds[i]) begin
                    storage[i] <= up_data[i];
                    ready[i]   <= 1'b1;
                end
            end

            // 2. Логика выдачи по порядку (Round-robin)
            // Проверяем: либо данные уже в буфере, либо пришли в этом такте
            if (ready[out_ptr] || up_vlds[out_ptr]) begin
                down_vld_r <= 1'b1;
                
                // Приоритет входящим данным, если это тот самый индекс, который мы ждем
                if (up_vlds[out_ptr])
                    down_data_r <= up_data[out_ptr];
                else
                    down_data_r <= storage[out_ptr];

                // Сбрасываем флаг готовности для текущего индекса
                ready[out_ptr] <= 1'b0;

                // Переходим к следующему индексу
                if (out_ptr == n_inputs - 1)
                    out_ptr <= '0;
                else
                    out_ptr <= out_ptr + 1'b1;
            end else begin
                down_vld_r <= 1'b0;
            end
        end
    end

    // Привязываем внутренние регистры к выходным портам через assign
    // Это решает ошибку "not a valid l-value"
    assign down_vld  = down_vld_r;
    assign down_data = down_data_r;
endmodule
