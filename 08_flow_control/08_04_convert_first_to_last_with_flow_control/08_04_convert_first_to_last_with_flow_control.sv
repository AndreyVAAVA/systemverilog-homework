//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module convert_first_to_last_with_flow_control
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    output               up_ready,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    input                down_ready,
    output               down_last,
    output [width - 1:0] down_data
);

    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // The module should respect and set correct valid and ready signals
    // to control flow from the upstream and to the downstream.

    // Регистры для хранения одного такта данных
    logic [width-1:0] data_buffer;
    logic             buffer_full;

    // 1. Управление готовностью (Ready)
    // Мы можем принять данные, если буфер пуст или если мы его сейчас освобождаем
    assign up_ready = !buffer_full || (down_ready && down_valid);

    // 2. Управление валидностью (Valid)
    // Мы выдаем данные из буфера, только если пришло СЛЕДУЮЩЕЕ слово от источника,
    // потому что только так мы поймем, является ли слово в буфере последним (last).
    assign down_valid = buffer_full && up_valid;

    // 3. Данные и сигнал Last
    // Слово в буфере является последним, если текущее входное слово — первое в новом пакете
    assign down_last  = up_first;
    assign down_data  = data_buffer;

    // 4. Логика обновления буфера
    always_ff @(posedge clock) begin
        if (reset) begin
            buffer_full <= 1'b0;
            data_buffer <= '0;
        end else begin
            // Если рукопожатие на входе произошло, записываем данные в буфер
            if (up_valid && up_ready) begin
                data_buffer <= up_data;
                buffer_full <= 1'b1;
            end 
            // Если данных на входе нет, но мы успешно отдали то, что было в буфере
            else if (down_valid && down_ready) begin
                buffer_full <= 1'b0;
            end
        end
    end
endmodule
