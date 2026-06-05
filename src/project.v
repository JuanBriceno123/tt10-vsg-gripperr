`default_nettype none

module tt_um_brazo_digital (
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: input path  (unused)
    output wire [7:0] uio_out,  // IOs: output path (unused)
    output wire [7:0] uio_oe,   // IOs: enable path (0 = input)
    input  wire       ena,      // High when this design is selected
    input  wire       clk,      // 50 MHz clock
    input  wire       rst_n     // Active-low reset
);

    // Pines bidireccionales no usados configurados como entradas
    assign uio_out = 8'b0;
    assign uio_oe  = 8'b0;
    wire _unused = &{ena, uio_in, ui_in[7:6], 1'b0};

    // Cables internos hacia brazo_digital_top
    wire step_x, dir_x;
    wire step_y, dir_y;
    wire step_grip, dir_grip;

    // Asignación de salidas de los motores a los pines físicos de TT
    assign uo_out[0] = step_x;
    assign uo_out[1] = dir_x;
    assign uo_out[2] = step_y;
    assign uo_out[3] = dir_y;
    assign uo_out[4] = step_grip;
    assign uo_out[5] = dir_grip;
    assign uo_out[7:6] = 2'b00;  // Pines no usados a masa

    // INSTANCIA DEL TOP LEVEL INICIAL
    brazo_digital_top core (
        .clk             (clk),
        .rst_n           (rst_n),

        .noisy_btn_x_cw  (ui_in[0]),
        .noisy_btn_x_ccw (ui_in[1]),
        .noisy_btn_y_cw  (ui_in[2]),
        .noisy_btn_y_ccw (ui_in[3]),
        .noisy_dip_grip  (ui_in[4]),
        .noisy_sw_limit  (ui_in[5]),

        .step_x          (step_x),
        .dir_x           (dir_x),
        .step_y          (step_y),
        .dir_y           (dir_y),
        .step_grip       (step_grip),
        .dir_grip        (dir_grip)
    );

endmodule