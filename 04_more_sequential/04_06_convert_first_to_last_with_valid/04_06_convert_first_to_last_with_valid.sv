//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module conv_first_to_last_no_ready
# (
    parameter width = 8
)
(
    input                clock,
    input                reset,

    input                up_valid,
    input                up_first,
    input  [width - 1:0] up_data,

    output               down_valid,
    output               down_last,
    output [width - 1:0] down_data
);
    // Task:
    // Implement a module that converts 'first' input status signal
    // to the 'last' output status signal.
    //
    // See README for full description of the task with timing diagram.

    reg [width-1:0] r_data;
    reg             r_has_data;

    always @(posedge clock) begin
        if (reset) begin
            r_has_data <= 1'b0;
            r_data     <= {width{1'b0}};
        end else if (up_valid) begin
            // Если up_valid=0, мы храним старое значение.
            r_has_data <= 1'b1;
            r_data     <= up_data;
        end
    end

    assign down_data = r_data;

    // Мы выдаем данные наружу (valid=1), только когда:
    // 1. У нас есть что выдавать (r_has_data).
    // 2. Снаружи нас "подпирают" новыми данными (up_valid), выталкивая старые.
    assign down_valid = r_has_data && up_valid;

    // Это последний байт, если мы сейчас его выдаем (down_valid),
    // а новый входящий байт, который его вытолкнул, помечен как 'first'.
    assign down_last = down_valid && up_first;
endmodule
