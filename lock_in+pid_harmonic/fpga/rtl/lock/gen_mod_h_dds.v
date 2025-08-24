`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//
// Modulation generator.
// Creates harmonic functions of 4096 data length using direct digital synthesis, 
// no more hold per point method
// MAKE SURE THE LOOK UP TABLE LENGTH IS A BINARY POWER, NO MODULO WORK AROUND FOR NOW.
// otherwise, the harmonic generation will not be correct!
// Creates sin, cos_ref, cos1, cos2, cos3, and square signals, whose half period is set by using sqp input.
//
//////////////////////////////////////////////////////////////////////////////////

//(* keep_hierarchy = "yes" *)
module gen_mod_h_dds
(
    input clk,rst,
    input           [12-1:0] phase,    // Phase control, now just an offset
    input           [32-1:0] phase_sq, // Phase control, no longer used
    input           [14-1:0] hp,   // Harmonic period control via PHASE increment
    output signed   [14-1:0] sin_ref,
    output signed   [14-1:0] cos_ref, cos_1f, cos_2f, cos_3f,
    output          [12-1:0] cntu_w, // now tracks current phase
    output                   harmonic_trig // square_trig
);



    // [PERIOD_LEN_PARAM DOCK]
    localparam accum_width = 8'd32 ; // phase accumulator width
    localparam lut_width = 8'd12; // lookup table bit depth
    localparam mem_large =  14'd4096   ; // complete signal large
    // [PERIOD_LEN_PARAM DOCK END]

    // LUT Memory Declarations
    // IMPORTANT: Your .dat files must now contain 4094 points for the full wave.
    reg signed [14-1:0] memory_sin_r [mem_large-1:0];
    initial $readmemb("data_full_sin1_4096points.dat", memory_sin_r);

    reg signed [14-1:0] memory_cos_r [mem_large-1:0];
    initial $readmemb("data_full_cos1_4096points.dat", memory_cos_r);

    // ------------- Core DDS Logic ------------

    // The phase accumulator is the core of the DDS
    reg [accum_width-1:0] phase_accumulator;

    // The 'hp' input is now the phase increment, which sets the frequency.
    wire [accum_width-1:0] phase_increment = {hp, {(accum_width-14){1'b0}}};

    // The 'phase' input is now a phase offset. We scale it to the accumulator width.
    wire [accum_width-1:0] phase_offset = {phase, {(accum_width-12){1'b0}}};

    always @(posedge clk) begin
        if (rst) begin
            phase_accumulator <= {accum_width{1'b0}};
        end else begin
            phase_accumulator <= phase_accumulator + phase_increment;
        end
    end

    // Detect when the accumulator wraps around (completes a full cycle)
    assign harmonic_trig = (phase_accumulator + phase_increment) < phase_accumulator;


    // ------------- Phase Generation for Harmonics -------------

    wire [accum_width-1:0] phase_ref_full = phase_accumulator;
    wire [accum_width-1:0] phase_1f_full  = phase_ref_full * 1 + phase_offset ; // Fundamental
    wire [accum_width-1:0] phase_2f_full  = phase_ref_full * 2 + phase_offset; // 2nd Harmonic
    wire [accum_width-1:0] phase_3f_full  = phase_ref_full * 3 + phase_offset; // 3rd Harmonic

    wire [lut_width-1:0] addr_ref = phase_ref_full[accum_width-1 : accum_width-lut_width];
    wire [lut_width-1:0] addr_1f  = phase_1f_full[accum_width-1 : accum_width-lut_width];
    wire [lut_width-1:0] addr_2f  = phase_2f_full[accum_width-1 : accum_width-lut_width];
    wire [lut_width-1:0] addr_3f  = phase_3f_full[accum_width-1 : accum_width-lut_width];

    assign sin_ref = memory_sin_r[addr_ref];
    assign cos_ref = memory_cos_r[addr_ref];
    assign cos_1f  = memory_cos_r[addr_1f];
    assign cos_2f  = memory_cos_r[addr_2f];
    assign cos_3f  = memory_cos_r[addr_3f];

    // ------------- Outputs -------------
    // Output the current phase angle (which is now the direct LUT address)

    assign cntu_w = addr_ref; // Sliced to fit the 12-bit output port

    endmodule

