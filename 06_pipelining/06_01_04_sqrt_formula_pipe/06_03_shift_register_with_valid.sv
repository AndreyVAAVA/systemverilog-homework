//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module one_bit_wide_shift_register_with_reset
# (
    parameter depth = 8
)
(
    input  clk,
    input  rst,
    input  in_data,
    output out_data
);
    logic [depth - 1:0] data;

    always_ff @ (posedge clk)
        if (rst)
            data <= '0;
        else
            data <= { data [depth - 2:0], in_data };

    assign out_data = data [depth - 1];

endmodule

//----------------------------------------------------------------------------

module shift_register
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input  [width - 1:0] in_data,
    output [width - 1:0] out_data
);
    logic [width - 1:0] data [0:depth - 1];

    always_ff @ (posedge clk)
    begin
        data [0] <= in_data;

        for (int i = 1; i < depth; i ++)
            data [i] <= data [i - 1];
    end

    assign out_data = data [depth - 1];

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module shift_register_with_valid
# (
    parameter width = 8, depth = 8
)
(
    input                clk,
    input                rst,

    input                in_vld,
    input  [width - 1:0] in_data,

    output               out_vld,
    output [width - 1:0] out_data
);

    // Task:
    //
    // Implement a variant of a shift register module
    // that moves a transfer of data only if this transfer is valid.
    //
    // For the discussion of shift registers
    // see the article by Yuri Panchul published in
    // FPGA-Systems Magazine :: FSM :: Issue ALFA (state_0)
    // You can download this issue from https://fpga-systems.ru/fsm#state_0

	    // Массив для хранения битов валидности
    logic [depth - 1:0] vld;
    // Массив для хранения данных
    logic [width - 1:0] data [0 : depth - 1];

    // 1. Регистры валидности (оранжевая цепочка на диаграмме)
    // Эти регистры должны иметь сброс (rst)
    always_ff @(posedge clk) begin
        if (rst) begin
            vld <= '0;
        end else begin
            vld[0] <= in_vld;
            for (int i = 1; i < depth; i++) begin
                vld[i] <= vld[i-1];
            end
        end
    end

    // 2. Регистры данных с сигналом разрешения записи (зеленая цепочка)
    // Данные перемещаются только если на входе конкретной стадии стоит vld=1
    always_ff @(posedge clk) begin
        // Первая стадия: пишем, если входящие данные валидны
        if (in_vld) begin
            data[0] <= in_data;
        end

        // Последующие стадии: пишем, если валидны данные в предыдущей стадии
        for (int i = 1; i < depth; i++) begin
            if (vld[i-1]) begin
                data[i] <= data[i-1];
            end
        end
    end

    // Назначаем выходы последней стадии
    assign out_vld  = vld [depth - 1];
    assign out_data = data[depth - 1];
	
endmodule
