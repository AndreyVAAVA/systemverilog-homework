module sqrt_formula_distributor
# (
    parameter formula = 1,
              impl    = 1
)
(
    input         clk,
    input         rst,

    input         arg_vld,
    input  [31:0] a,
    input  [31:0] b,
    input  [31:0] c,

    output        res_vld,
    output [31:0] res
);

    // Task:
    //
    // Implement a module that will calculate formula 1 or formula 2
    // based on the parameter values. The module must be pipelined.
    // It should be able to accept new triple of arguments a, b, c arriving
    // at every clock cycle.
    //
    // The idea of the task is to implement hardware task distributor,
    // that will accept triplet of the arguments and assign the task
    // of the calculation formula 1 or formula 2 with these arguments
    // to the free FSM-based internal module.
    //
    // The first step to solve the task is to fill 03_04 and 03_05 files.
    //
    // Note 1:
    // Latency of the module "formula_1_isqrt" should be clarified from the corresponding waveform
    // or simply assumed to be equal 50 clock cycles.
    //
    // Note 2:
    // The task assumes idealized distributor (with 50 internal computational blocks),
    // because in practice engineers rarely use more than 10 modules at ones.
    // Usually people use 3-5 blocks and utilize stall in case of high load.
    //
    // Hint:
    // Instantiate sufficient number of "formula_1_impl_1_top", "formula_1_impl_2_top",
    // or "formula_2_top" modules to achieve desired performance.

    // Увеличиваем N до 64, так как реальная задержка последовательных
    // вычислений 3-х корней + такты FSM составляет ~53-54 такта.
    // N=50 не хватает при пиковой нагрузке (запросы каждый такт).
    localparam N = 64; 

    // Счетчик (индекс) для распределения задач (Round-Robin)
    logic [$clog2(N)-1:0] index;

    always_ff @(posedge clk) begin
        if (rst) begin
            index <= '0;
        end
        else if (arg_vld) begin
            // Кольцевой счетчик от 0 до N-1
            if (index == N - 1)
                index <= '0;
            else
                index <= index + 1'b1;
        end
    end

    // Внутренние шины для связи с экземплярами
    logic [N-1:0] inst_arg_vld;
    logic [N-1:0] inst_res_vld;
    logic [31:0]  inst_res [N];

    // Генерация N внутренних вычислительных модулей
    genvar i;
    generate
        for (i = 0; i < N; i++) begin : gen_blocks
            
            // Запускающий сигнал подается только на свободный модуль с текущим индексом
            assign inst_arg_vld[i] = arg_vld && (index == i);

            // Инстанцирование нужного top-модуля на основе параметров
            if (formula == 1 && impl == 1) begin : gen_f1_i1
                formula_1_impl_1_top inst (
                    .clk    (clk),
                    .rst    (rst),
                    .arg_vld(inst_arg_vld[i]),
                    .a      (a),
                    .b      (b),
                    .c      (c),
                    .res_vld(inst_res_vld[i]),
                    .res    (inst_res[i])
                );
            end
            else if (formula == 1 && impl == 2) begin : gen_f1_i2
                formula_1_impl_2_top inst (
                    .clk    (clk),
                    .rst    (rst),
                    .arg_vld(inst_arg_vld[i]),
                    .a      (a),
                    .b      (b),
                    .c      (c),
                    .res_vld(inst_res_vld[i]),
                    .res    (inst_res[i])
                );
            end
            else if (formula == 2) begin : gen_f2
                formula_2_top inst (
                    .clk    (clk),
                    .rst    (rst),
                    .arg_vld(inst_arg_vld[i]),
                    .a      (a),
                    .b      (b),
                    .c      (c),
                    .res_vld(inst_res_vld[i]),
                    .res    (inst_res[i])
                );
            end
        end
    endgenerate

    // Выходной флаг готовности (Логическое ИЛИ всех валидных сигналов)
    assign res_vld = |inst_res_vld;

    // Промежуточный регистр для мультиплексора результата
    logic [31:0] res_mux;

    always_comb begin
        res_mux = '0; 
        for (int j = 0; j < N; j++) begin
            if (inst_res_vld[j]) begin
                res_mux = inst_res[j];
            end
        end
    end

    // Вывод результата
    assign res = res_mux;
	
endmodule
