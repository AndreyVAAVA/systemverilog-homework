//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module generate_tokens_by_number_with_flow_control
#(
    WIDTH = 4
)
(
    input                 clk,
    input                 rst,

    input                 up_valid,
    output                up_ready,
    input  [WIDTH-1 : 0]  n_tokens,

    output                down_valid,
    input                 down_ready,
    output                down_token
);

    // Task:
    // Implement a module that recive an integer N_tokens and generate N_tokens pulses. The module must use signals valid-ready for
    // transfer tokens.

    // Счетчик оставшихся импульсов
    logic [WIDTH-1:0] pulses_left;

    // Готовы принять новую задачу только когда полностью разгрузили предыдущую
    assign up_ready = (pulses_left == {WIDTH{1'b0}});

    // Выход валиден, пока есть что отдавать
    assign down_valid = (pulses_left != {WIDTH{1'b0}});

    // Сам токен - это логическая "1", которая активна только вместе с valid
    assign down_token = down_valid;

    always_ff @(posedge clk) begin
        if (rst) begin
            pulses_left <= {WIDTH{1'b0}};
        end else begin
            // 1. Прием новой команды (Handshake на входе)
            if (up_valid && up_ready) begin
                pulses_left <= n_tokens;
            end 
            // 2. Выдача токена (Handshake на выходе)
            // Условие (pulses_left != 0) уже заложено в down_valid
            else if (down_valid && down_ready) begin
                pulses_left <= pulses_left - 1'b1;
            end
        end
    end
endmodule
