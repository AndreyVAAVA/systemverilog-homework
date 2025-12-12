//----------------------------------------------------------------------------
// Example
//----------------------------------------------------------------------------

module sort_two_floats_ab (
    input        [FLEN - 1:0] a,
    input        [FLEN - 1:0] b,

    output logic [FLEN - 1:0] res0,
    output logic [FLEN - 1:0] res1,
    output                    err
);

    logic a_less_or_equal_b;

    f_less_or_equal i_floe (
        .a   ( a                 ),
        .b   ( b                 ),
        .res ( a_less_or_equal_b ),
        .err ( err               )
    );

    always_comb begin : a_b_compare
        if ( a_less_or_equal_b ) begin
            res0 = a;
            res1 = b;
        end
        else
        begin
            res0 = b;
            res1 = a;
        end
    end

endmodule

//----------------------------------------------------------------------------
// Example - different style
//----------------------------------------------------------------------------

module sort_two_floats_array
(
    input        [0:1][FLEN - 1:0] unsorted,
    output logic [0:1][FLEN - 1:0] sorted,
    output                         err
);

    logic u0_less_or_equal_u1;

    f_less_or_equal i_floe
    (
        .a   ( unsorted [0]        ),
        .b   ( unsorted [1]        ),
        .res ( u0_less_or_equal_u1 ),
        .err ( err                 )
    );

    always_comb
        if (u0_less_or_equal_u1)
            sorted = unsorted;
        else
              {   sorted [0],   sorted [1] }
            = { unsorted [1], unsorted [0] };

endmodule

//----------------------------------------------------------------------------
// Task
//----------------------------------------------------------------------------

module sort_three_floats (
    input        [0:2][FLEN - 1:0] unsorted,
    output logic [0:2][FLEN - 1:0] sorted,
    output                         err
);

    // Task:
    // Implement a module that accepts three Floating-Point numbers and outputs them in the increasing order.
    // The module should be combinational with zero latency.
    // The solution can use up to three instances of the "f_less_or_equal" module.
    //
    // Notes:
    // res0 must be less or equal to the res1
    // res1 must be less or equal to the res2
    //
    // The FLEN parameter is defined in the "import/preprocessed/cvw/config-shared.vh" file
    // and usually equal to the bit width of the double-precision floating-point number, FP64, 64 bits.

    logic [0:2][FLEN - 1:0] filtered1;
    logic [0:2][FLEN - 1:0] filtered2;

    logic sort01_step1, sort12_step2, sort01_step3;
    logic err01_step1, err12_step2, err01_step3;

    f_less_or_equal comp01_step1 (
        .a   ( unsorted[0]      ),
        .b   ( unsorted[1]      ),
        .res ( sort01_step1     ),
        .err ( err01_step1     )
    );

    f_less_or_equal comp12_step2 (
        .a   ( filtered1[1]     ),
        .b   ( filtered1[2]     ),
        .res ( sort12_step2     ),
        .err ( err12_step2     )
    );

    f_less_or_equal comp01_step3 (
        .a   ( filtered2[0]     ),
        .b   ( filtered2[1]     ),
        .res ( sort01_step3     ),
        .err ( err01_step3     )
    );

    always_comb begin
        // Step 1
        if (sort01_step1) begin
            filtered1[0] = unsorted[0];
            filtered1[1] = unsorted[1];
        end
        else begin
            filtered1[0] = unsorted[1];
            filtered1[1] = unsorted[0];
        end
        filtered1[2] = unsorted[2];
	// Step 2
        if (sort12_step2) begin
            filtered2[1] = filtered1[1];
            filtered2[2] = filtered1[2];
        end
        else begin
            filtered2[1] = filtered1[2];
            filtered2[2] = filtered1[1];
        end
        filtered2[0] = filtered1[0];
	// Step 3
        if (sort01_step3) begin
            sorted[0] = filtered2[0];
            sorted[1] = filtered2[1];
        end
        else begin
            sorted[0] = filtered2[1];
            sorted[1] = filtered2[0];
        end
        sorted[2] = filtered2[2];
    end

    assign err = err01_step1 | err12_step2 | err01_step3;

endmodule
